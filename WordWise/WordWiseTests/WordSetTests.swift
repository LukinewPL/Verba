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
}
