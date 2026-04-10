import Foundation
class SM2Service {
    func buildReviewQueue(from words: [Word], now: Date = Date()) -> [Word] {
        let dueReviewedWords = words
            .filter { isDueReviewWord($0, now: now) }
            .shuffled()
        if !dueReviewedWords.isEmpty {
            return dueReviewedWords
        }

        return words
            .filter { isNewWord($0) }
            .shuffled()
    }

    func rate(_ word: Word, quality: Int) {
        let clampedQuality = min(5, max(0, quality))

        word.lastReviewed = Date()
        word.difficultyRating = clampedQuality
        
        if clampedQuality < 3 {
            word.repetitions = 0
            word.interval = 1
        } else {
            if word.repetitions == 0 {
                word.interval = 1
            } else if word.repetitions == 1 {
                word.interval = 6
            } else {
                word.interval = Int(round(Double(word.interval) * word.easeFactor))
            }
            word.repetitions += 1
        }
        
        let difficultyAdjustment = 0.1 - (5.0 - Double(clampedQuality)) * (0.08 + (5.0 - Double(clampedQuality)) * 0.02)
        word.easeFactor += difficultyAdjustment
        word.easeFactor = max(1.3, word.easeFactor)
        
        word.isMastered = word.repetitions >= 5
        word.nextReview = Calendar.current.date(byAdding: .day, value: word.interval, to: Date()) ?? Date()
    }

    private func isDueReviewWord(_ word: Word, now: Date) -> Bool {
        guard word.lastReviewed != nil else { return false }
        return word.nextReview <= now
    }

    private func isNewWord(_ word: Word) -> Bool {
        word.lastReviewed == nil
    }
}
