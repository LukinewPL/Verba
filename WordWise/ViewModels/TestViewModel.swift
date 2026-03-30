import SwiftUI
import SwiftData
import Observation

@Observable @MainActor final class TestViewModel {
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
    private var repository: (any WordRepositoryProtocol)?
    private var sm2Service = SM2Service()
    private var dismissAction: (() -> Void)?
    private var pendingAdvanceWorkItem: DispatchWorkItem?

    init(set: WordSet) {
        self.set = set
    }

    func setup(repository: any WordRepositoryProtocol, dismiss: @escaping () -> Void) {
        self.repository = repository
        self.dismissAction = dismiss
    }

    func reset() {
        pendingAdvanceWorkItem?.cancel()
        pendingAdvanceWorkItem = nil
        isSetup = true
        isFinished = false
        currentIdx = 0
        score = 0
        answer = ""
        queue = []
        mcOptions = []
        wrongAnswers = []
        selectedOption = nil
        feedbackColor = .clear
        showCorrectAnswer = false
        wordQualities = [:]
    }

    func abandonTest() {
        reset()
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
        pendingAdvanceWorkItem?.cancel()
        pendingAdvanceWorkItem = nil
        queue = Array(set.words.shuffled().prefix(Int(questionCount)))
        guard !queue.isEmpty else {
            finishTest()
            return
        }
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
        guard let current else { return }
        selectedOption = option
        if normalize(option) == normalize(set.target(for: current)) {
            score += 1
            feedbackColor = .green
            AudioFeedback.shared.playCorrect()
            wordQualities[current.id] = 4
        } else {
            feedbackColor = .red
            AudioFeedback.shared.playWrong()
            wrongAnswers.append((prompt, target))
            wordQualities[current.id] = 1
        }
        nextStep()
    }

    func submitOpen() {
        guard let current else { return }
        selectedOption = answer
        if normalize(answer) == normalize(set.target(for: current)) {
            score += 1
            feedbackColor = .green
            AudioFeedback.shared.playCorrect()
            wordQualities[current.id] = 4
        } else {
            feedbackColor = .red
            AudioFeedback.shared.playWrong()
            wrongAnswers.append((prompt, target))
            wordQualities[current.id] = 1
            showCorrectAnswer = true
        }
        nextStep()
    }

    private func nextStep() {
        showCorrectAnswer = false
        pendingAdvanceWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            guard let self else { return }
            withAnimation {
                self.feedbackColor = .clear
                self.answer = ""
                self.currentIdx += 1
                if self.currentIdx >= self.queue.count { self.finishTest() }
                else { self.prepareOptions() }
            }
        }
        pendingAdvanceWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8, execute: workItem)
    }

    private func finishTest() {
        pendingAdvanceWorkItem?.cancel()
        pendingAdvanceWorkItem = nil
        isFinished = true
        NSSound(named: "Glass")?.play()
        for w in queue {
            let quality = wordQualities[w.id] ?? 3
            sm2Service.rate(w, quality: quality)
        }
    }

    func finishTestAndSave() {
        pendingAdvanceWorkItem?.cancel()
        pendingAdvanceWorkItem = nil
        if !queue.isEmpty, let repo = repository {
            let session = StudySession(wordSetID: set.id)
            session.wordsStudied = queue.count
            session.correctAnswers = score
            repo.insertSession(session)
        }
        dismissAction?()
    }

    private func normalize(_ text: String) -> String {
        text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: "\u{2019}", with: "'")
            .replacingOccurrences(of: "\u{00A0}", with: " ")
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
            .folding(options: .diacriticInsensitive, locale: .current)
    }
}
