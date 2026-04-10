import XCTest
@testable import Verba

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

@MainActor
final class FlashcardsViewModelTests: XCTestCase {
    func testResetLoadsCurrentWordAndClearsFlipState() {
        let set = WordSet(name: "flash", words: [Word(polish: "pies", english: "dog")])
        let vm = FlashcardsViewModel(set: set)
        vm.isFlipped = true

        vm.reset()

        XCTAssertNotNil(vm.current)
        XCTAssertFalse(vm.isFlipped)
    }

    func testFlipTogglesState() {
        let set = WordSet(name: "flash", words: [Word(polish: "pies", english: "dog")])
        let vm = FlashcardsViewModel(set: set)

        vm.flip()
        XCTAssertTrue(vm.isFlipped)
        vm.flip()
        XCTAssertFalse(vm.isFlipped)
    }

    func testNextWordEventuallyEndsSession() {
        let set = WordSet(name: "flash", words: [Word(polish: "pies", english: "dog")])
        let vm = FlashcardsViewModel(set: set)

        vm.nextWord()

        XCTAssertNil(vm.current)
    }

    func testProgressReflectsCurrentPosition() {
        let set = WordSet(name: "flash", words: [
            Word(polish: "pies", english: "dog"),
            Word(polish: "kot", english: "cat")
        ])
        let vm = FlashcardsViewModel(set: set)

        XCTAssertEqual(vm.totalCount, 2)
        XCTAssertGreaterThan(vm.progress, 0)
    }

    func testFrontBackTextFollowDirection() {
        let word = Word(polish: "pies", english: "dog")
        let set = WordSet(name: "flash", words: [word], dir: TranslationDirection.polishToEnglish.rawValue)
        let vm = FlashcardsViewModel(set: set)

        XCTAssertEqual(vm.frontText, "pies")
        XCTAssertEqual(vm.backText, "dog")

        set.translationDirectionRaw = TranslationDirection.englishToPolish.rawValue
        XCTAssertEqual(vm.frontText, "dog")
        XCTAssertEqual(vm.backText, "pies")
    }

    func testLanguageCodesFollowDirection() {
        let set = WordSet(name: "flash", words: [Word(polish: "pies", english: "dog")])
        let vm = FlashcardsViewModel(set: set)

        XCTAssertEqual(vm.frontLanguageCode, "pl")
        XCTAssertEqual(vm.backLanguageCode, "en")

        set.translationDirectionRaw = TranslationDirection.englishToPolish.rawValue
        XCTAssertEqual(vm.frontLanguageCode, "en")
        XCTAssertEqual(vm.backLanguageCode, "pl")
    }
}
