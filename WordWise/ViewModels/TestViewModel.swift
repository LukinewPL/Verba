import SwiftUI
import SwiftData
import Observation

@Observable final class TestViewModel {
    var set: WordSet
    var isSetup = true
    var isFinished = false
    var questionCount = 10.0
    var isMultipleChoice = true
    var queue: [Word] = []
    var currentIdx = 0
    var score = 0
    var answer = ""
    var mcOptions: [String] = []
    var feedbackColor: Color = .clear
    var wrongAnswers: [(String, String)] = []
    var selectedOption: String? = nil
    var wordQualities: [UUID: Int] = [:]
    var showCorrectAnswer = false
    
    // Dependencies
    private var modelContext: ModelContext?
    private var dismissAction: (() -> Void)?
    
    init(set: WordSet) {
        self.set = set
    }
    
    func setup(modelContext: ModelContext, dismiss: @escaping () -> Void) {
        self.modelContext = modelContext
        self.dismissAction = dismiss
    }
    
    var current: Word? { queue.indices.contains(currentIdx) ? queue[currentIdx] : nil }
    
    var prompt: String {
        guard let current else { return "" }
        return set.prompt(for: current)
    }
    
    var target: String {
        guard let current else { return "" }
        return set.target(for: current)
    }
    
    func startTest() {
        queue = Array(set.words.shuffled().prefix(Int(questionCount)))
        currentIdx = 0
        score = 0
        isFinished = false
        isSetup = false
        wrongAnswers = []
        wordQualities = [:]
        showCorrectAnswer = false
        prepareOptions()
    }
    
    func prepareOptions() {
        guard let curr = current else { finishTest(); return }
        if isMultipleChoice {
            let correct = target
            var others = set.words
                .filter { $0.id != curr.id }
                .map { set.target(for: $0) }
            others = Array(Set(others))
            others.shuffle()
            mcOptions = Array(others.prefix(3)) + [correct]
            mcOptions.shuffle()
        }
        selectedOption = nil
    }
    
    func submitMC(_ option: String) {
        selectedOption = option
        if option == target {
            score += 1
            feedbackColor = .green
            AudioFeedback.shared.playCorrect()
            wordQualities[current!.id] = 4
        } else {
            feedbackColor = .red
            AudioFeedback.shared.playWrong()
            wrongAnswers.append((prompt, target))
            wordQualities[current!.id] = 1
        }
        nextStep()
    }
    
    func submitOpen() {
        selectedOption = answer
        if answer.lowercased().trimmingCharacters(in: .whitespaces) == target.lowercased() {
            score += 1
            feedbackColor = .green
            AudioFeedback.shared.playCorrect()
            wordQualities[current!.id] = 4
        } else {
            feedbackColor = .red
            AudioFeedback.shared.playWrong()
            wrongAnswers.append((prompt, target))
            wordQualities[current!.id] = 1
            showCorrectAnswer = true
        }
        nextStep()
    }
    
    private func nextStep() {
        showCorrectAnswer = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation {
                self.feedbackColor = .clear
                self.answer = ""
                self.currentIdx += 1
                if self.currentIdx >= self.queue.count { self.finishTest() }
                else { self.prepareOptions() }
            }
        }
    }
    
    private func finishTest() {
        isFinished = true
        NSSound(named: "Glass")?.play()
        for w in queue {
            let quality = wordQualities[w.id] ?? 3
            SM2Engine.rate(w, quality: quality)
        }
    }
    
    func finishTestAndSave() {
        if !queue.isEmpty, let ctx = modelContext {
            let session = StudySession(wordSetID: set.id)
            session.wordsStudied = queue.count
            session.correctAnswers = score
            ctx.insert(session)
            try? ctx.save()
        }
        dismissAction?()
    }
}
