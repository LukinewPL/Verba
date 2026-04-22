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
        XCTAssertEqual(vm.queue.map(\.id), [newWord.id])
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

    func testResetSessionIncludesNewWordsWhenDueReviewsExist() {
        let due = Word(polish: "pies", english: "dog")
        due.lastReviewed = Date().addingTimeInterval(-3_600)
        due.nextReview = Date().addingTimeInterval(-300)

        let newWordOne = Word(polish: "kot", english: "cat")
        let newWordTwo = Word(polish: "ptak", english: "bird")

        let set = WordSet(name: "session", words: [due, newWordOne, newWordTwo])
        let vm = StudySessionViewModel(set: set)

        vm.resetSession()

        let activeIDs = Set(([vm.current].compactMap { $0?.id }) + vm.queue.map(\.id))
        XCTAssertEqual(activeIDs, Set([due.id, newWordOne.id, newWordTwo.id]))
        XCTAssertEqual(vm.current?.id, due.id)
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
        XCTAssertTrue(vm.current?.isStudyCompleted == true)
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
        XCTAssertFalse(vm.current?.isStudyCompleted == true)

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
        XCTAssertFalse(vm.current?.isStudyCompleted == true)
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

    func testCheckAnswerPersistsWordProgress() {
        let repository = MockWordRepository()
        let vm = makeVM(words: [("pies", "dog")])
        vm.setup(repository: repository)
        vm.answer = "dog"

        vm.checkAnswer(onSuccess: {}, onFailure: {})

        XCTAssertTrue(repository.saveCalled)
        XCTAssertEqual(repository.saveCallCount, 1)
    }

    func testHasFullyLearnedSetIsTrueOnlyWhenAllWordsAreCompletedInStudy() {
        let completed = Word(polish: "pies", english: "dog")
        completed.isStudyCompleted = true
        let pending = Word(polish: "kot", english: "cat")

        let vmPartial = StudySessionViewModel(set: WordSet(name: "session", words: [completed, pending]))
        XCTAssertFalse(vmPartial.hasFullyLearnedSet)

        pending.isStudyCompleted = true
        let vmFull = StudySessionViewModel(set: WordSet(name: "session", words: [completed, pending]))
        XCTAssertTrue(vmFull.hasFullyLearnedSet)
    }

    func testRestartLearningFromBeginningClearsLearningStateForAllWords() {
        let first = Word(polish: "pies", english: "dog")
        first.isMastered = true
        first.repetitions = 7
        first.interval = 21
        first.easeFactor = 2.9
        first.lastReviewed = Date().addingTimeInterval(-86_400)
        first.nextReview = Date().addingTimeInterval(86_400)
        first.difficultyRating = 4

        let second = Word(polish: "kot", english: "cat")
        second.isMastered = true
        second.repetitions = 5
        second.lastReviewed = Date().addingTimeInterval(-3_600)
        second.nextReview = Date().addingTimeInterval(3_600)
        second.difficultyRating = 5

        let set = WordSet(name: "session", words: [first, second])
        let vm = StudySessionViewModel(set: set)

        vm.restartLearningFromBeginning()

        for word in set.words {
            XCTAssertFalse(word.isMastered)
            XCTAssertEqual(word.repetitions, 0)
            XCTAssertEqual(word.interval, 1)
            XCTAssertEqual(word.easeFactor, 2.5, accuracy: 0.0001)
            XCTAssertNil(word.lastReviewed)
            XCTAssertEqual(word.difficultyRating, 0)
            XCTAssertFalse(word.isStudyCompleted)
        }

        XCTAssertNotNil(vm.current)
        let activeIDs = Set(([vm.current].compactMap { $0?.id }) + vm.queue.map(\.id))
        XCTAssertEqual(activeIDs, Set(set.words.map(\.id)))
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
