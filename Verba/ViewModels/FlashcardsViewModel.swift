import SwiftUI
import SwiftData
import Observation

@Observable @MainActor final class FlashcardsViewModel {
    var set: WordSet
    var queue: [Word] = []
    var current: Word?
    var isFlipped: Bool = false
    private var history: [Word] = []
    private var deckWords: [Word] = []
    
    init(set: WordSet) {
        self.set = set
        reset()
    }
    
    func reset() {
        deckWords = set.words.shuffled()
        queue = deckWords
        history = []
        isFlipped = false
        advanceToNextWord(recordCurrent: false)
    }
    
    func nextWord() {
        advanceToNextWord(recordCurrent: true)
    }

    func goToNextWord() {
        nextWord()
    }

    @discardableResult
    func goToPreviousWord() -> Bool {
        guard let previous = history.popLast() else { return false }

        if let current {
            queue.insert(current, at: 0)
        }

        current = previous
        isFlipped = false
        return true
    }
    
    func flip() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
            isFlipped.toggle()
        }
    }
    
    var frontText: String {
        guard let current else { return "" }
        return set.translationDirection == .polishToEnglish ? current.polish : current.english
    }
    
    var backText: String {
        guard let current else { return "" }
        return set.translationDirection == .polishToEnglish ? current.english : current.polish
    }
    
    var totalCount: Int {
        deckWords.count
    }
    
    var currentPosition: Int {
        guard totalCount > 0 else { return 0 }
        if current == nil { return totalCount }
        return min(totalCount, history.count + 1)
    }
    
    var progress: Double {
        guard totalCount > 0 else { return 0 }
        return Double(currentPosition) / Double(totalCount)
    }
    
    var frontLanguageCode: String {
        self.set.translationDirection == .polishToEnglish ? "pl" : "en"
    }
    
    var backLanguageCode: String {
        self.set.translationDirection == .polishToEnglish ? "en" : "pl"
    }

    var canGoBack: Bool {
        !history.isEmpty
    }

    private func advanceToNextWord(recordCurrent: Bool) {
        if recordCurrent, let current {
            markWordAsReviewed(current)
            history.append(current)
        }

        if queue.isEmpty {
            current = nil
        } else {
            current = queue.removeFirst()
            isFlipped = false
        }
    }

    private func markWordAsReviewed(_ word: Word) {
        guard word.lastReviewed == nil else { return }
        let now = Date()
        word.lastReviewed = now
        if word.nextReview < now {
            word.nextReview = now
        }
    }
}
