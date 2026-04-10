import SwiftUI
import SwiftData
import Observation

@Observable @MainActor final class StudySessionViewModel {
    var set: WordSet
    var queue: [Word] = []
    var current: Word?
    var answer: String = ""
    var feedback: Color = .clear
    var feedbackIsSuccess = false
    var attemptedCount = 0
    var correctCount = 0
    var hasSaved = false
    var hint: String = ""
    
    // Dependencies
    private var repository: (any WordRepositoryProtocol)?
    private let sm2Service: SM2Service
    private let normalizer: any AnswerNormalizing
    private let audioFeedback: any AudioFeedbackPlaying
    private var promptAnswerPool: [String: Set<String>] = [:]
    private var usedPromptAnswers: [String: Set<String>] = [:]
    
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
        resetSession()
    }
    
    func resetSession() {
        queue = set.words.shuffled()
        attemptedCount = 0
        correctCount = 0
        hasSaved = false
        feedback = .clear
        feedbackIsSuccess = false
        answer = ""
        hint = ""
        usedPromptAnswers = [:]
        rebuildPromptAnswerPool()
        nextWord()
    }
    
    func checkAnswer(onSuccess: @escaping () -> Void, onFailure: @escaping () -> Void) {
        attemptedCount += 1
        let promptKey = normalizer.normalize(prompt)
        let matchedTranslation = matchedAvailableTranslation(input: answer, promptKey: promptKey)
        let isCorrect = matchedTranslation != nil
        let usedHint = !hint.isEmpty
        
        if isCorrect {
            if !usedHint, let matchedTranslation {
                usedPromptAnswers[promptKey, default: []].insert(matchedTranslation)
            }
            if !usedHint {
                correctCount += 1
            }
            feedback = .green
            feedbackIsSuccess = true
            audioFeedback.playCorrect()
            if let w = current {
                if usedHint {
                    sm2Service.rate(w, quality: 2)
                    queue.append(w)
                } else {
                    sm2Service.rate(w, quality: 4)
                }
            }
            onSuccess()
        } else {
            feedback = .red
            feedbackIsSuccess = false
            audioFeedback.playWrong()
            if let w = current {
                sm2Service.rate(w, quality: 1)
                queue.append(w)
            }
            onFailure()
        }
    }
    
    func nextWord() {
        if queue.isEmpty {
            current = nil
            if attemptedCount > 0 && !hasSaved {
                audioFeedback.playCompletion(success: correctCount > 0)
            }
        } else {
            current = queue.removeFirst()
            hint = ""
        }
    }
    
    func provideHint() {
        guard current != nil else { return }
        guard !hasTypedFirstTargetLetter else { return }
        if !targetFirstLetter.isEmpty {
            hint = targetFirstLetter
        }
    }

    func playHintRevealFeedback() {
        audioFeedback.playHintReveal()
    }

    func playHintVaporFeedback() {
        audioFeedback.playHintVapor()
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
    
    var targetFirstLetter: String {
        let trimmed = hintCandidate.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let first = trimmed.first else { return "" }
        return String(first)
    }
    
    var hasTypedFirstTargetLetter: Bool {
        let trimmedAnswer = answer.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedAnswer.isEmpty, !targetFirstLetter.isEmpty else { return false }
        guard let firstAnswer = trimmedAnswer.first else { return false }
        return normalizer.normalize(String(firstAnswer)) == normalizer.normalize(targetFirstLetter)
    }
    
    var shouldShowInlineHint: Bool {
        !hint.isEmpty && feedback == .clear
    }
    
    private var hintCandidate: String {
        let promptKey = normalizer.normalize(prompt)
        guard !promptKey.isEmpty else { return target }
        guard let allAnswers = promptAnswerPool[promptKey], !allAnswers.isEmpty else { return target }
        
        let usedAnswers = usedPromptAnswers[promptKey] ?? []
        var availableAnswers = allAnswers.subtracting(usedAnswers)
        if availableAnswers.isEmpty {
            availableAnswers = allAnswers
        }
        
        let normalizedCurrentTarget = normalizer.normalize(target)
        if availableAnswers.contains(normalizedCurrentTarget) {
            return normalizedCurrentTarget
        }
        
        return availableAnswers.sorted().first ?? target
    }
    
    private func matchedAvailableTranslation(input: String, promptKey: String) -> String? {
        let normalizedInput = normalizer.normalize(input)
        guard !normalizedInput.isEmpty else { return nil }
        
        let allAnswers = promptAnswerPool[promptKey] ?? normalizer.variants(for: target)
        guard !allAnswers.isEmpty else { return nil }
        
        let usedAnswers = usedPromptAnswers[promptKey] ?? []
        var availableAnswers = allAnswers.subtracting(usedAnswers)
        if availableAnswers.isEmpty {
            availableAnswers = allAnswers
        }
        
        return availableAnswers.contains(normalizedInput) ? normalizedInput : nil
    }
    
    private func rebuildPromptAnswerPool() {
        promptAnswerPool = [:]
        
        for word in set.words {
            let promptKey = normalizer.normalize(set.prompt(for: word))
            guard !promptKey.isEmpty else { continue }
            
            let variants = normalizer.variants(for: set.target(for: word))
            guard !variants.isEmpty else { continue }
            
            promptAnswerPool[promptKey, default: []].formUnion(variants)
        }
    }
    
}
