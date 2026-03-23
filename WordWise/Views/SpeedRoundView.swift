import SwiftUI
import SwiftData
import Combine

struct SpeedRoundView: View {
    @Environment(LanguageManager.self) private var lm
    @Bindable var set: WordSet
    @State private var queue: [Word] = []
    @State private var current: Word?
    @State private var answer = ""
    @State private var attemptedCount = 0
    @State private var correctCount = 0
    @State private var timeLeft = 60
    @State private var isActive = false
    @State private var isFinished = false
    @State private var feedbackColor: Color = .clear
    @State private var showWrongAnswer = false
    @State private var hasSaved = false
    @State private var isStarted = false
    @State private var showRecordBlast = false
    @FocusState private var isFocused: Bool
    @Environment(\.modelContext) private var ctx
    
    private let timerPublisher = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    @Environment(\.dismiss) private var dismiss
    
    var prompt: String {
        guard let current else { return "" }
        return set.prompt(for: current)
    }
    var target: String {
        guard let current else { return "" }
        return set.target(for: current)
    }
    
    var body: some View {
        VStack {
            if !isStarted {
                VStack(spacing: 30) {
                    Text(set.name).font(.largeTitle.bold()).foregroundColor(.white)
                    Text("\(lm.t("record")): \(set.bestScore)").font(.title2).foregroundColor(.glassCyan)
                    Button(lm.t("start")) { 
                        Task { @MainActor in startGame() }
                    }.buttonStyle(GlassButtonStyle())
                }.glassEffect().padding()
            } else if isFinished {
                VStack(spacing: 20) {
                    Text(lm.t("time_up")).font(.largeTitle).foregroundColor(.white).padding()
                    if showRecordBlast {
                        Text("🏆 \(lm.t("new_record"))!").font(.title.bold()).foregroundColor(.orange).transition(.scale)
                    }
                    Text("\(lm.t("score")): \(correctCount)").font(.title).foregroundColor(.glassCyan).padding()
                    Button(lm.t("done")) { dismiss() }.buttonStyle(GlassButtonStyle())
                }.glassEffect().padding()
            } else {
                HStack {
                    Spacer()
                    ZStack {
                        Circle().stroke(Color.white.opacity(0.3), lineWidth: 5)
                        Circle().trim(from: 0, to: CGFloat(timeLeft) / 60.0)
                            .stroke(Color.glassCyan, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                            .animation(.linear(duration: 1), value: timeLeft)
                        Text("\(timeLeft)").font(.title3).foregroundColor(.white).bold()
                    }.frame(width: 60, height: 60)
                }.padding()
                
                Spacer()
                if let _ = current {
                    Text(prompt).font(.system(size: 60, weight: .bold)).foregroundColor(.white).glassEffect().padding()
                    
                    if showWrongAnswer {
                        Text(target).font(.title).foregroundColor(.red).padding()
                    } else {
                        TextField("...", text: $answer)
                            .textFieldStyle(.plain)
                            .padding()
                            .glassEffect()
                            .font(.title)
                            .frame(maxWidth: 600)
                            .padding(.horizontal, 40)
                            .focused($isFocused)
                            .onSubmit { checkAnswer() }
                    }
                }
                Spacer()
                Text("\(lm.t("score")): \(correctCount)").foregroundColor(.white).font(.headline).padding()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(feedbackColor.opacity(0.3).ignoresSafeArea())
        .background(Color.deepNavy.ignoresSafeArea())
        .onReceive(timerPublisher) { _ in
            if isStarted && isActive && !isFinished {
                if timeLeft > 0 { timeLeft -= 1 } 
                else { finishGameView() }
            }
        }
        .onDisappear { saveSession() }
    }
    
    private func startGame() {
        queue = set.words.shuffled()
        correctCount = 0
        attemptedCount = 0
        timeLeft = 60
        isFinished = false
        isActive = true
        isStarted = true
        showRecordBlast = false
        nextWord()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { isFocused = true }
    }
    
    private func nextWord() {
        if queue.isEmpty { queue = set.words.shuffled() }
        current = queue.isEmpty ? nil : queue.removeFirst()
    }
    
    private func finishGameView() {
        isActive = false
        isFinished = true
        current = nil
        
        if correctCount > set.bestScore {
            set.bestScore = correctCount
            showRecordBlast = true
            do {
                try ctx.save()
            } catch {
                print("WordWise: Save failed — \(error)")
            }
        }
        
        if correctCount > 0 {
            NSSound(named: "Glass")?.play()
        } else {
            NSSound(named: "Basso")?.play()
        }
    }
    
    private func checkAnswer() {
        let cleanAns = answer.lowercased().trimmingCharacters(in: .whitespaces)
        let cleanTar = target.lowercased().trimmingCharacters(in: .whitespaces)
        attemptedCount += 1
        
        if cleanAns == cleanTar {
            correctCount += 1
            if let w = current { SM2Engine.rate(w, quality: 4) }
            feedbackColor = .green; AudioFeedback.shared.playCorrect()
            answer = ""
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                feedbackColor = .clear; nextWord(); isFocused = true
            }
        } else {
            if let w = current { SM2Engine.rate(w, quality: 1) }
            feedbackColor = .red; AudioFeedback.shared.playWrong()
            showWrongAnswer = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                showWrongAnswer = false
                feedbackColor = .clear
                answer = ""
                nextWord()
                isFocused = true
            }
        }
    }
    
    private func saveSession() {
        guard !hasSaved && attemptedCount > 0 else { return }
        let session = StudySession(wordSetID: set.id)
        session.wordsStudied = attemptedCount
        session.correctAnswers = correctCount
        ctx.insert(session)
        try? ctx.save()
        hasSaved = true
    }
}
