import XCTest
@testable import WordWise

final class WordSetTests: XCTestCase {
    func testPromptTargetLogic() {
        let set = WordSet(name: "Test Set")
        let word = Word(polish: "jabłko", english: "apple")
        set.words.append(word)
        
        // Default direction (pl -> en)
        set.translationDirectionRaw = TranslationDirection.polishToEnglish.rawValue
        XCTAssertEqual(set.prompt(for: word), "jabłko")
        XCTAssertEqual(set.target(for: word), "apple")
        
        // Reverse direction (en -> pl)
        set.translationDirectionRaw = TranslationDirection.englishToPolish.rawValue
        XCTAssertEqual(set.prompt(for: word), "apple")
        XCTAssertEqual(set.target(for: word), "jabłko")
    }

    func testTranslationDirectionFallsBackToDefaultForInvalidRawValue() {
        let set = WordSet(name: "Fallback")
        set.translationDirectionRaw = 999

        XCTAssertEqual(set.translationDirection, .polishToEnglish)
    }

    func testInitializerSetsLanguagesAndWords() {
        let word = Word(polish: "dom", english: "house")
        let set = WordSet(
            name: "Langs",
            words: [word],
            dir: TranslationDirection.englishToPolish.rawValue,
            source: "en",
            target: "pl"
        )

        XCTAssertEqual(set.words.count, 1)
        XCTAssertEqual(set.sourceLanguage, "en")
        XCTAssertEqual(set.targetLanguage, "pl")
        XCTAssertEqual(set.translationDirection, .englishToPolish)
    }
}
