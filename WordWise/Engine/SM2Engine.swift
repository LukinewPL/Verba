import Foundation
struct SM2Engine {
    static func rate(_ word: Word, quality: Int) {
        word.lastReviewed = Date(); word.difficultyRating = quality
        if quality < 3 { word.repetitions = 0; word.interval = 1 } else {
            if word.repetitions == 0 { word.interval = 1 }
            else if word.repetitions == 1 { word.interval = 6 }
            else { word.interval = Int(round(Double(word.interval) * word.easeFactor)) }
            word.repetitions += 1
        }
        word.easeFactor += (0.1 - (5.0 - Double(quality)) * (0.08 + (5.0 - Double(quality)) * 0.02))
        word.easeFactor = max(1.3, word.easeFactor)
        word.isMastered = word.repetitions >= 5
        word.nextReview = Calendar.current.date(byAdding: .day, value: word.interval, to: Date()) ?? Date()
    }
}
