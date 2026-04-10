import SwiftData
import Foundation

@Model final class StudySession {
    var id: UUID = UUID()
    var date: Date = Date()
    var wordsStudied: Int = 0
    var correctAnswers: Int = 0
    var wordSetID: UUID = UUID()

    init(wordSetID: UUID) {
        self.wordSetID = wordSetID
    }
}
