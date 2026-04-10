import SwiftUI
import SwiftData
import Observation

@Observable @MainActor final class FlashcardsViewModel {
    var set: WordSet
    var queue: [Word] = []
    var current: Word?
    var isFlipped: Bool = false
    
    init(set: WordSet) {
        self.set = set
        reset()
    }
    
    func reset() {
        queue = set.words.shuffled()
        isFlipped = false
        nextWord()
    }
    
    func nextWord() {
        if queue.isEmpty {
            current = nil
        } else {
            current = queue.removeFirst()
            isFlipped = false
        }
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
        self.set.words.count
    }
    
    var currentPosition: Int {
        guard totalCount > 0 else { return 0 }
        if current == nil { return totalCount }
        return max(1, totalCount - queue.count)
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
}
