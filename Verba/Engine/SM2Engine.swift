import Foundation
class SM2Service {
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
}
