import SwiftUI
import SwiftData
import Observation

@Observable @MainActor final class SpeedRoundViewModel {
    var set: WordSet
    var queue: [Word] = []
    var current: Word?
    var answer = ""
    var attemptedCount = 0
    var correctCount = 0
    var timeLeft = 60
    var isActive = false
    var isFinished = false
    var feedbackColor: Color = .clear
    var showWrongAnswer = false
    var hasSaved = false
    var isStarted = false
    var showRecordBlast = false

    // Dependencies
    private var repository: (any WordRepositoryProtocol)?
    private var sm2Service = SM2Service()

    init(set: WordSet) {
        self.set = set
    }

    func setup(repository: any WordRepositoryProtocol) {
        self.repository = repository
    }

    func startGame() {
        queue = set.words.shuffled()
        answer = ""
        correctCount = 0
        attemptedCount = 0
        timeLeft = 60
        isFinished = false
        isActive = true
        isStarted = true
        hasSaved = false
        showWrongAnswer = false
        feedbackColor = .clear
        showRecordBlast = false
        nextWord()
    }

    func nextWord() {
        if queue.isEmpty { queue = set.words.shuffled() }
        current = queue.isEmpty ? nil : queue.removeFirst()
    }

    func tick() {
        if isStarted && isActive && !isFinished {
            if timeLeft > 0 {
                timeLeft -= 1
            } else {
                finishGame()
            }
        }
    }

    func finishGame() {
        isActive = false
        isFinished = true
        current = nil

        if correctCount > set.bestScore {
            set.bestScore = correctCount
            showRecordBlast = true
            repository?.save()
        }

        if correctCount > 0 {
            NSSound(named: "Glass")?.play()
        } else {
            NSSound(named: "Basso")?.play()
        }
    }

    func checkAnswer(onSuccess: @escaping () -> Void, onFailure: @escaping () -> Void) {
        guard let current else { return }
        let cleanAns = normalize(answer)
        let cleanTar = normalize(set.target(for: current))
        attemptedCount += 1

        if cleanAns == cleanTar {
            correctCount += 1
            sm2Service.rate(current, quality: 4)
            feedbackColor = .green
            AudioFeedback.shared.playCorrect()
            answer = ""
            showWrongAnswer = false
            onSuccess()
        } else {
            sm2Service.rate(current, quality: 1)
            feedbackColor = .red
            AudioFeedback.shared.playWrong()
            showWrongAnswer = true
            onFailure()
        }
    }

    func saveSession() {
        guard !hasSaved && attemptedCount > 0 else { return }
        let session = StudySession(wordSetID: set.id)
        session.wordsStudied = attemptedCount
        session.correctAnswers = correctCount

        repository?.insertSession(session)
        hasSaved = true
    }

    var prompt: String {
        guard let current else { return "" }
        return set.prompt(for: current)
    }

    var target: String {
        guard let current else { return "" }
        return set.target(for: current)
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
