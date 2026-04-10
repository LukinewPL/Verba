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
    var feedbackIsSuccess = false
    var showWrongAnswer = false
    var hasSaved = false
    var isStarted = false
    var showRecordBlast = false

    // Dependencies
    private var repository: (any WordRepositoryProtocol)?
    private let sm2Service: SM2Service
    private let normalizer: any AnswerNormalizing
    private let audioFeedback: any AudioFeedbackPlaying
    private var roundWords: [Word] = []

    init(
        set: WordSet,
        sm2Service: SM2Service? = nil,
        normalizer: (any AnswerNormalizing)? = nil,
        audioFeedback: (any AudioFeedbackPlaying)? = nil
    ) {
        self.set = set
        self.sm2Service = sm2Service ?? SM2Service()
        self.normalizer = normalizer ?? AnswerNormalizer()
        self.audioFeedback = audioFeedback ?? AudioFeedback.shared
    }

    func setup(repository: any WordRepositoryProtocol) {
        self.repository = repository
    }

    func startGame() {
        roundWords = sm2Service.buildReviewQueue(from: set.words)
        queue = roundWords
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
        feedbackIsSuccess = false
        showRecordBlast = false
        nextWord()
    }

    func nextWord() {
        guard !roundWords.isEmpty else {
            current = nil
            return
        }
        if queue.isEmpty { queue = roundWords.shuffled() }
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

        audioFeedback.playCompletion(success: correctCount > 0)
    }

    func checkAnswer(onSuccess: @escaping () -> Void, onFailure: @escaping () -> Void) {
        guard let current else { return }
        let cleanAns = normalizer.normalize(answer)
        let cleanTar = normalizer.normalize(set.target(for: current))
        attemptedCount += 1

        if cleanAns == cleanTar {
            correctCount += 1
            sm2Service.rate(current, quality: 4)
            feedbackColor = .green
            feedbackIsSuccess = true
            audioFeedback.playCorrect()
            answer = ""
            showWrongAnswer = false
            onSuccess()
        } else {
            sm2Service.rate(current, quality: 1)
            feedbackColor = .red
            feedbackIsSuccess = false
            audioFeedback.playWrong()
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

}
