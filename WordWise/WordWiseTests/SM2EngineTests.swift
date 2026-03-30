import Foundation
import XCTest
@testable import WordWise

final class SM2EngineTests: XCTestCase {
    var service = SM2Service()

    func testInitialRatingSetsFirstRepetition() {
        let word = Word(polish: "test", english: "test")

        service.rate(word, quality: 4)

        XCTAssertEqual(word.repetitions, 1)
        XCTAssertEqual(word.interval, 1)
        XCTAssertGreaterThan(word.lastReviewed ?? .distantPast, Date().addingTimeInterval(-10))
        XCTAssertEqual(word.difficultyRating, 4)
    }

    func testSecondCorrectRatingSetsSixDayInterval() {
        let word = Word(polish: "test", english: "test")

        service.rate(word, quality: 5)
        service.rate(word, quality: 5)

        XCTAssertEqual(word.repetitions, 2)
        XCTAssertEqual(word.interval, 6)
    }

    func testThirdCorrectRatingUsesEaseFactorMultiplier() {
        let word = Word(polish: "test", english: "test")
        word.easeFactor = 2.0

        service.rate(word, quality: 5) // repetitions: 1, interval: 1
        service.rate(word, quality: 5) // repetitions: 2, interval: 6
        service.rate(word, quality: 5) // repetitions: 3, interval grows by updated ease factor

        XCTAssertEqual(word.repetitions, 3)
        XCTAssertEqual(word.interval, 13)
    }

    func testQualityBelowThreeResetsRepetitionsAndInterval() {
        let word = Word(polish: "test", english: "test")

        service.rate(word, quality: 5)
        XCTAssertEqual(word.repetitions, 1)

        service.rate(word, quality: 2)

        XCTAssertEqual(word.repetitions, 0)
        XCTAssertEqual(word.interval, 1)
    }

    func testEaseFactorNeverDropsBelowMinimum() {
        let word = Word(polish: "test", english: "test")

        for _ in 0..<20 {
            service.rate(word, quality: 0)
        }

        XCTAssertGreaterThanOrEqual(word.easeFactor, 1.3)
    }

    func testMasteryThresholdAfterFiveSuccessfulRepetitions() {
        let word = Word(polish: "test", english: "test")

        XCTAssertFalse(word.isMastered)
        for _ in 1...5 {
            service.rate(word, quality: 4)
        }

        XCTAssertTrue(word.isMastered)
    }

    func testNextReviewAdvancesAtLeastOneDay() {
        let word = Word(polish: "test", english: "test")

        service.rate(word, quality: 4)

        XCTAssertGreaterThan(word.nextReview, Date())
    }
}

@MainActor
final class StudySessionViewModelTests: XCTestCase {
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

@MainActor
final class SpeedRoundViewModelTests: XCTestCase {
    func testStartGameResetsStateAndActivatesGame() {
        let vm = makeVM(words: [("pies", "dog"), ("kot", "cat")])
        vm.correctCount = 9
        vm.attemptedCount = 9
        vm.timeLeft = 1
        vm.isFinished = true

        vm.startGame()

        XCTAssertTrue(vm.isStarted)
        XCTAssertTrue(vm.isActive)
        XCTAssertFalse(vm.isFinished)
        XCTAssertEqual(vm.timeLeft, 60)
        XCTAssertEqual(vm.correctCount, 0)
        XCTAssertEqual(vm.attemptedCount, 0)
        XCTAssertNotNil(vm.current)
    }

    func testTickDecrementsOnlyWhenGameIsActive() {
        let vm = makeVM(words: [("pies", "dog")])
        vm.timeLeft = 10

        vm.tick()
        XCTAssertEqual(vm.timeLeft, 10)

        vm.isStarted = true
        vm.isActive = true
        vm.tick()
        XCTAssertEqual(vm.timeLeft, 9)
    }

    func testTickAtZeroFinishesGame() {
        let vm = makeVM(words: [("pies", "dog")])
        vm.startGame()
        vm.timeLeft = 0

        vm.tick()

        XCTAssertTrue(vm.isFinished)
        XCTAssertFalse(vm.isActive)
        XCTAssertNil(vm.current)
    }

    func testCorrectAnswerUpdatesScore() {
        let vm = makeVM(words: [("pies", "dog")])
        vm.startGame()
        vm.answer = vm.target

        var success = false
        vm.checkAnswer(onSuccess: { success = true }, onFailure: {})

        XCTAssertTrue(success)
        XCTAssertEqual(vm.correctCount, 1)
        XCTAssertEqual(vm.attemptedCount, 1)
        XCTAssertFalse(vm.showWrongAnswer)
    }

    func testWrongAnswerMarksWrongState() {
        let vm = makeVM(words: [("pies", "dog")])
        vm.startGame()
        vm.answer = "wrong"

        var failed = false
        vm.checkAnswer(onSuccess: {}, onFailure: { failed = true })

        XCTAssertTrue(failed)
        XCTAssertEqual(vm.correctCount, 0)
        XCTAssertEqual(vm.attemptedCount, 1)
        XCTAssertTrue(vm.showWrongAnswer)
    }

    func testFinishGameUpdatesBestScoreAndCallsSaveOnRecord() {
        let repository = MockWordRepository()
        let set = WordSet(name: "speed", words: [Word(polish: "pies", english: "dog")])
        set.bestScore = 1
        let vm = SpeedRoundViewModel(set: set)
        vm.setup(repository: repository)
        vm.correctCount = 3

        vm.finishGame()

        XCTAssertEqual(set.bestScore, 3)
        XCTAssertTrue(vm.showRecordBlast)
        XCTAssertTrue(repository.saveCalled)
    }

    func testFinishGameWithoutRecordDoesNotCallSave() {
        let repository = MockWordRepository()
        let set = WordSet(name: "speed", words: [Word(polish: "pies", english: "dog")])
        set.bestScore = 5
        let vm = SpeedRoundViewModel(set: set)
        vm.setup(repository: repository)
        vm.correctCount = 2

        vm.finishGame()

        XCTAssertFalse(vm.showRecordBlast)
        XCTAssertFalse(repository.saveCalled)
    }

    func testSaveSessionPersistsOnlyOnce() {
        let repository = MockWordRepository()
        let vm = makeVM(words: [("pies", "dog")])
        vm.setup(repository: repository)
        vm.attemptedCount = 7
        vm.correctCount = 4

        vm.saveSession()
        vm.saveSession()

        XCTAssertEqual(repository.sessions.count, 1)
        XCTAssertEqual(repository.sessions.first?.wordsStudied, 7)
        XCTAssertEqual(repository.sessions.first?.correctAnswers, 4)
    }

    private func makeVM(words: [(String, String)]) -> SpeedRoundViewModel {
        SpeedRoundViewModel(set: WordSet(name: "speed", words: words.map { Word(polish: $0.0, english: $0.1) }))
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

@MainActor
final class TestViewModelTests: XCTestCase {
    func testStartTestWithNoWordsFinishesImmediately() {
        let set = WordSet(name: "empty", words: [])
        let vm = TestViewModel(set: set)

        vm.startTest()

        XCTAssertTrue(vm.isFinished)
        XCTAssertTrue(vm.queue.isEmpty)
    }

    func testStartTestRespectsQuestionCount() {
        let set = WordSet(name: "test", words: [
            Word(polish: "jeden", english: "one"),
            Word(polish: "dwa", english: "two"),
            Word(polish: "trzy", english: "three")
        ])
        let vm = TestViewModel(set: set)
        vm.questionCount = 2

        vm.startTest()

        XCTAssertEqual(vm.queue.count, 2)
        XCTAssertFalse(vm.isSetup)
        XCTAssertFalse(vm.isFinished)
    }

    func testPrepareOptionsContainsCorrectAnswerInMultipleChoiceMode() {
        let set = WordSet(name: "test", words: [
            Word(polish: "jeden", english: "one"),
            Word(polish: "dwa", english: "two"),
            Word(polish: "trzy", english: "three"),
            Word(polish: "cztery", english: "four")
        ])
        let vm = TestViewModel(set: set)
        vm.isMultipleChoice = true
        vm.startTest()

        XCTAssertTrue(vm.mcOptions.contains(vm.target))
        XCTAssertLessThanOrEqual(vm.mcOptions.count, 4)
    }

    func testSubmitMCCorrectIncreasesScoreAndAdvances() async {
        let set = WordSet(name: "test", words: [Word(polish: "pies", english: "dog")])
        let vm = TestViewModel(set: set)
        vm.startTest()

        vm.submitMC(vm.target)
        try? await Task.sleep(nanoseconds: 950_000_000)

        XCTAssertEqual(vm.score, 1)
        XCTAssertTrue(vm.isFinished)
    }

    func testSubmitMCWrongAddsWrongAnswer() async {
        let set = WordSet(name: "test", words: [Word(polish: "pies", english: "dog")])
        let vm = TestViewModel(set: set)
        vm.startTest()

        vm.submitMC("wrong")
        try? await Task.sleep(nanoseconds: 950_000_000)

        XCTAssertEqual(vm.score, 0)
        XCTAssertEqual(vm.wrongAnswers.count, 1)
        XCTAssertTrue(vm.isFinished)
    }

    func testSubmitOpenWrongAddsWrongAnswer() async {
        let set = WordSet(name: "test", words: [Word(polish: "pies", english: "dog")])
        let vm = TestViewModel(set: set)
        vm.isMultipleChoice = false
        vm.startTest()
        vm.answer = "cat"

        vm.submitOpen()
        try? await Task.sleep(nanoseconds: 950_000_000)

        XCTAssertEqual(vm.wrongAnswers.count, 1)
        XCTAssertTrue(vm.isFinished)
    }

    func testFinishTestAndSavePersistsSessionAndCallsDismiss() {
        let set = WordSet(name: "test", words: [Word(polish: "pies", english: "dog")])
        let vm = TestViewModel(set: set)
        let repository = MockWordRepository()
        var dismissed = false
        vm.setup(repository: repository, dismiss: { dismissed = true })
        vm.queue = set.words
        vm.score = 1

        vm.finishTestAndSave()

        XCTAssertEqual(repository.sessions.count, 1)
        XCTAssertEqual(repository.sessions.first?.wordsStudied, 1)
        XCTAssertEqual(repository.sessions.first?.correctAnswers, 1)
        XCTAssertTrue(dismissed)
    }

    func testAbandonTestResetsState() {
        let set = WordSet(name: "test", words: [Word(polish: "pies", english: "dog")])
        let vm = TestViewModel(set: set)
        vm.startTest()
        vm.score = 7
        vm.answer = "x"

        vm.abandonTest()

        XCTAssertTrue(vm.isSetup)
        XCTAssertFalse(vm.isFinished)
        XCTAssertEqual(vm.score, 0)
        XCTAssertEqual(vm.answer, "")
        XCTAssertTrue(vm.queue.isEmpty)
    }
}
