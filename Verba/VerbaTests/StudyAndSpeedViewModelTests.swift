import XCTest
@testable import Verba

@MainActor
final class StudySessionViewModelTests: XCTestCase {
    func testResetSessionPrioritizesDueReviewedWords() {
        let due = Word(polish: "pies", english: "dog")
        due.lastReviewed = Date().addingTimeInterval(-3_600)
        due.nextReview = Date().addingTimeInterval(-300)

        let future = Word(polish: "kot", english: "cat")
        future.lastReviewed = Date().addingTimeInterval(-3_600)
        future.nextReview = Date().addingTimeInterval(3_600)

        let newWord = Word(polish: "ptak", english: "bird")

        let set = WordSet(name: "session", words: [due, future, newWord])
        let vm = StudySessionViewModel(set: set)

        vm.resetSession()

        XCTAssertEqual(vm.current?.id, due.id)
        XCTAssertTrue(vm.queue.isEmpty)
    }

    func testResetSessionFallsBackToNewWordsWhenNoDueReviews() {
        let future = Word(polish: "kot", english: "cat")
        future.lastReviewed = Date().addingTimeInterval(-3_600)
        future.nextReview = Date().addingTimeInterval(3_600)

        let newWord = Word(polish: "ptak", english: "bird")
        let set = WordSet(name: "session", words: [future, newWord])
        let vm = StudySessionViewModel(set: set)

        vm.resetSession()

        XCTAssertEqual(vm.current?.id, newWord.id)
        XCTAssertTrue(vm.queue.isEmpty)
    }

    func testResetSessionInitializesCurrentWordAndCounters() {
        let vm = makeVM(words: [("pies", "dog"), ("kot", "cat")])

        vm.attemptedCount = 5
        vm.correctCount = 4
        vm.hint = "x"
        vm.answer = "abc"
        vm.resetSession()

        XCTAssertNotNil(vm.current)
        XCTAssertEqual(vm.attemptedCount, 0)
        XCTAssertEqual(vm.correctCount, 0)
        XCTAssertEqual(vm.hint, "")
        XCTAssertEqual(vm.answer, "")
    }

    func testCorrectAnswerWithoutHintIncreasesScoreAndDoesNotRequeue() {
        let vm = makeVM(words: [("pies", "dog")])
        vm.answer = "dog"

        var success = false
        vm.checkAnswer(onSuccess: { success = true }, onFailure: {})

        XCTAssertTrue(success)
        XCTAssertEqual(vm.correctCount, 1)
        XCTAssertEqual(vm.attemptedCount, 1)
        XCTAssertEqual(vm.queue.count, 0)
    }

    func testCorrectAnswerWithHintRequeuesWordAndDoesNotIncreaseScore() {
        let vm = makeVM(words: [("pies", "dog")])
        vm.provideHint()
        vm.answer = "dog"

        var success = false
        vm.checkAnswer(onSuccess: { success = true }, onFailure: {})

        XCTAssertTrue(success)
        XCTAssertEqual(vm.correctCount, 0)
        XCTAssertEqual(vm.attemptedCount, 1)
        XCTAssertEqual(vm.queue.count, 1)

        vm.nextWord()
        XCTAssertEqual(vm.prompt, "pies")
    }

    func testWrongAnswerRequeuesCurrentWord() {
        let vm = makeVM(words: [("pies", "dog")])
        vm.answer = "cat"

        var failure = false
        vm.checkAnswer(onSuccess: {}, onFailure: { failure = true })

        XCTAssertTrue(failure)
        XCTAssertEqual(vm.correctCount, 0)
        XCTAssertEqual(vm.attemptedCount, 1)
        XCTAssertEqual(vm.queue.count, 1)
    }

    func testProvideHintSetsTargetFirstLetter() {
        let vm = makeVM(words: [("pies", "dog")])

        vm.provideHint()

        XCTAssertEqual(vm.hint, "d")
    }

    func testProvideHintDoesNothingWhenFirstTargetLetterAlreadyTyped() {
        let vm = makeVM(words: [("pies", "dog")])
        vm.answer = "d"

        vm.provideHint()

        XCTAssertEqual(vm.hint, "")
    }

    func testHasTypedFirstTargetLetterIgnoresWhitespaceAndCase() {
        let vm = makeVM(words: [("pies", "Dog")])
        vm.answer = "   Dorian "

        XCTAssertTrue(vm.hasTypedFirstTargetLetter)
    }

    func testCorrectAnswerNormalizesCurlyApostropheToAscii() {
        let vm = makeVM(words: [("zdanie", "don't")])
        vm.answer = "don’t"

        var success = false
        vm.checkAnswer(onSuccess: { success = true }, onFailure: {})

        XCTAssertTrue(success)
        XCTAssertEqual(vm.correctCount, 1)
    }

    func testUsedAnswerVariantForSamePromptIsConsumedUntilOtherVariantUsed() {
        let set = WordSet(
            name: "dup-prompt",
            words: [
                Word(polish: "dom", english: "house"),
                Word(polish: "dom", english: "home")
            ]
        )
        let vm = StudySessionViewModel(set: set)
        vm.resetSession()

        let first = set.words[0]
        let second = set.words[1]
        vm.current = first
        vm.queue = [second]
        vm.answer = "house"
        vm.checkAnswer(onSuccess: {}, onFailure: {})
        vm.nextWord()

        vm.answer = "house"
        var failed = false
        vm.checkAnswer(onSuccess: {}, onFailure: { failed = true })
        XCTAssertTrue(failed)

        vm.answer = "home"
        var success = false
        vm.checkAnswer(onSuccess: { success = true }, onFailure: {})
        XCTAssertTrue(success)
    }

    func testAnswerWithHintDoesNotConsumeVariant() {
        let vm = makeVM(words: [("dom", "house/home")])
        vm.provideHint()
        vm.answer = "house"
        vm.checkAnswer(onSuccess: {}, onFailure: {})

        vm.nextWord()
        vm.answer = "house"

        var success = false
        vm.checkAnswer(onSuccess: { success = true }, onFailure: {})
        XCTAssertTrue(success)
    }

    func testSaveSessionStoresResultOnlyOnce() {
        let repository = MockWordRepository()
        let vm = makeVM(words: [("pies", "dog")])
        vm.setup(repository: repository)
        vm.attemptedCount = 3
        vm.correctCount = 2

        vm.saveSession()
        vm.saveSession()

        XCTAssertEqual(repository.sessions.count, 1)
        XCTAssertEqual(repository.sessions.first?.wordsStudied, 3)
        XCTAssertEqual(repository.sessions.first?.correctAnswers, 2)
    }

    private func makeVM(words: [(String, String)]) -> StudySessionViewModel {
        let set = WordSet(name: "session", words: words.map { Word(polish: $0.0, english: $0.1) })
        let vm = StudySessionViewModel(set: set)
        vm.resetSession()
        return vm
    }
}

final class SpeedRoundTimerProgressTests: XCTestCase {
    func testClampsProgressToFullRingWhenTimeExceedsLimit() {
        XCTAssertEqual(speedRoundTimerProgress(timeLeft: 999), 1, accuracy: 0.0001)
    }

    func testClampsProgressToEmptyRingWhenTimeIsNegative() {
        XCTAssertEqual(speedRoundTimerProgress(timeLeft: -5), 0, accuracy: 0.0001)
    }

    func testReturnsExpectedFractionForRemainingTime() {
        XCTAssertEqual(speedRoundTimerProgress(timeLeft: 55), 55.0 / 60.0, accuracy: 0.0001)
    }

    func testFormatsTimerLabelAsSingleCenteredString() {
        XCTAssertEqual(speedRoundTimerLabel(timeLeft: 54), "54s")
    }
}
