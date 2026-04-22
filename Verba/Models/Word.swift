import SwiftData
import Foundation

@Model final class Word {
    var id: UUID = UUID()
    var polish: String = ""
    var english: String = ""
    var isMastered: Bool = false
    var easeFactor: Double = 2.5
    var interval: Int = 1
    var repetitions: Int = 0
    var nextReview: Date = Date()
    var lastReviewed: Date?
    var difficultyRating: Int = 0
    var isStudyCompleted: Bool = false
    var set: WordSet?
    
    init(polish: String, english: String) {
        self.polish = polish
        self.english = english
    }

    var isCompletedInStudy: Bool {
        isStudyCompleted
    }
}
