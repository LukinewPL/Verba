import SwiftUI
import SwiftData
import Foundation

enum TranslationDirection: Int, Codable {
    case polishToEnglish = 0
    case englishToPolish = 1
}

@Model final class WordSet {
    var id: UUID = UUID()
    var name: String = ""
    var createdAt: Date = Date()
    @Relationship(deleteRule: .cascade) var words: [Word] = []
    var translationDirectionRaw: Int = TranslationDirection.polishToEnglish.rawValue
    var bestScore: Int = 0
    var folder: Folder?
    var sourceLanguage: String = "en"
    var targetLanguage: String = "pl"

    var translationDirection: TranslationDirection {
        TranslationDirection(rawValue: translationDirectionRaw) ?? .polishToEnglish
    }

    func prompt(for word: Word) -> String {
        translationDirection == .polishToEnglish ? word.polish : word.english
    }

    func target(for word: Word) -> String {
        translationDirection == .polishToEnglish ? word.english : word.polish
    }

    init(id: UUID = UUID(), name: String, createdAt: Date = Date(), words: [Word] = [], dir: Int = TranslationDirection.polishToEnglish.rawValue, source: String = "en", target: String = "pl") {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.words = words
        self.translationDirectionRaw = dir
        self.sourceLanguage = source
        self.targetLanguage = target
    }
}
