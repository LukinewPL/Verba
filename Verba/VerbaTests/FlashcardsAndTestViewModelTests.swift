import XCTest
@testable import Verba

@MainActor
final class FlashcardsNavigationViewModelTests: XCTestCase {
    func testResetUsesOnlyDueReviewedWordsWhenAvailable() {
        let due = Word(polish: "jeden", english: "one")
        due.lastReviewed = Date().addingTimeInterval(-3_600)
        due.nextReview = Date().addingTimeInterval(-300)

        let future = Word(polish: "dwa", english: "two")
        future.lastReviewed = Date().addingTimeInterval(-3_600)
        future.nextReview = Date().addingTimeInterval(3_600)

        let newWord = Word(polish: "trzy", english: "three")
        let vm = FlashcardsViewModel(set: WordSet(name: "cards", words: [due, future, newWord]))

        XCTAssertEqual(vm.current?.id, due.id)
        XCTAssertTrue(vm.queue.isEmpty)
    }

    func testResetFallsBackToNewWordsWhenNoDueReviewedWordsExist() {
        let future = Word(polish: "dwa", english: "two")
        future.lastReviewed = Date().addingTimeInterval(-3_600)
        future.nextReview = Date().addingTimeInterval(3_600)

        let newWord = Word(polish: "trzy", english: "three")
        let vm = FlashcardsViewModel(set: WordSet(name: "cards", words: [future, newWord]))

        XCTAssertEqual(vm.current?.id, newWord.id)
        XCTAssertTrue(vm.queue.isEmpty)
    }

    func testGoToPreviousRestoresLastViewedCard() {
        let set = WordSet(name: "cards", words: [
            Word(polish: "jeden", english: "one"),
            Word(polish: "dwa", english: "two"),
            Word(polish: "trzy", english: "three")
        ])
        let vm = FlashcardsViewModel(set: set)
        let firstPrompt = vm.frontText

        vm.goToNextWord()
        let secondPrompt = vm.frontText
        vm.goToNextWord()

        let didGoBack = vm.goToPreviousWord()

        XCTAssertTrue(didGoBack)
        XCTAssertEqual(vm.frontText, secondPrompt)
        XCTAssertNotEqual(vm.frontText, firstPrompt)
    }

    func testGoToNextAfterGoingBackReturnsToDeferredCard() {
        let set = WordSet(name: "cards", words: [
            Word(polish: "jeden", english: "one"),
            Word(polish: "dwa", english: "two"),
            Word(polish: "trzy", english: "three")
        ])
        let vm = FlashcardsViewModel(set: set)

        vm.goToNextWord()
        vm.goToNextWord()
        let thirdPrompt = vm.frontText
        _ = vm.goToPreviousWord()

        vm.goToNextWord()

        XCTAssertEqual(vm.frontText, thirdPrompt)
    }

    func testGoToPreviousReturnsFalseOnFirstCard() {
        let vm = FlashcardsViewModel(set: WordSet(name: "cards", words: [
            Word(polish: "jeden", english: "one")
        ]))

        let didGoBack = vm.goToPreviousWord()

        XCTAssertFalse(didGoBack)
    }
}

@MainActor
final class TestViewModelTests: XCTestCase {
    func testStartTestUsesDueReviewedWordsWhenAvailable() {
        let due = Word(polish: "pies", english: "dog")
        due.lastReviewed = Date().addingTimeInterval(-3_600)
        due.nextReview = Date().addingTimeInterval(-300)

        let future = Word(polish: "kot", english: "cat")
        future.lastReviewed = Date().addingTimeInterval(-3_600)
        future.nextReview = Date().addingTimeInterval(3_600)

        let newWord = Word(polish: "ptak", english: "bird")
        let set = WordSet(name: "test", words: [due, future, newWord])
        let vm = TestViewModel(set: set, scheduler: ImmediateTestAdvanceScheduler())

        vm.startTest()

        XCTAssertEqual(vm.queue.map(\.id), [due.id])
    }

    func testStartTestFallsBackToNewWordsWhenNoDueReviewedWordsExist() {
        let future = Word(polish: "kot", english: "cat")
        future.lastReviewed = Date().addingTimeInterval(-3_600)
        future.nextReview = Date().addingTimeInterval(3_600)

        let newWord = Word(polish: "ptak", english: "bird")
        let set = WordSet(name: "test", words: [future, newWord])
        let vm = TestViewModel(set: set, scheduler: ImmediateTestAdvanceScheduler())

        vm.startTest()

        XCTAssertEqual(vm.queue.map(\.id), [newWord.id])
    }

    func testStartTestWithNoWordsFinishesImmediately() {
        let vm = makeSUT(words: [])

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
        let vm = TestViewModel(set: set, scheduler: ImmediateTestAdvanceScheduler())
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
        let vm = TestViewModel(set: set, scheduler: ImmediateTestAdvanceScheduler())
        vm.isMultipleChoice = true
        vm.startTest()

        XCTAssertTrue(vm.mcOptions.contains(vm.target))
        XCTAssertLessThanOrEqual(vm.mcOptions.count, 4)
    }

    func testSubmitMCCorrectIncreasesScoreAndAdvances() {
        let vm = makeSUT(words: [("pies", "dog")])
        vm.startTest()

        vm.submitMC(vm.target)

        XCTAssertEqual(vm.score, 1)
        XCTAssertTrue(vm.isFinished)
    }

    func testSubmitMCWrongAddsWrongAnswer() {
        let vm = makeSUT(words: [("pies", "dog")])
        vm.startTest()

        vm.submitMC("wrong")

        XCTAssertEqual(vm.score, 0)
        XCTAssertEqual(vm.wrongAnswers.count, 1)
        XCTAssertTrue(vm.isFinished)
    }

    func testSubmitMultipleChoiceOptionAtValidIndexUsesMatchingOption() {
        let set = WordSet(name: "test", words: [
            Word(polish: "pies", english: "dog"),
            Word(polish: "kot", english: "cat"),
            Word(polish: "dom", english: "house"),
            Word(polish: "auto", english: "car")
        ])
        let vm = TestViewModel(set: set, scheduler: ControlledTestAdvanceScheduler())
        vm.startTest()

        guard let correctIndex = vm.mcOptions.firstIndex(of: vm.target) else {
            return XCTFail("Expected correct option to be present")
        }

        let didSubmit = vm.submitMultipleChoiceOption(at: correctIndex)

        XCTAssertTrue(didSubmit)
        XCTAssertEqual(vm.score, 1)
        XCTAssertEqual(vm.selectedOption, vm.target)
    }

    func testSubmitMultipleChoiceOptionAtInvalidIndexDoesNothing() {
        let vm = makeSUT(words: [
            ("pies", "dog"),
            ("kot", "cat"),
            ("dom", "house"),
            ("auto", "car")
        ], scheduler: ControlledTestAdvanceScheduler())
        vm.startTest()

        let didSubmit = vm.submitMultipleChoiceOption(at: 9)

        XCTAssertFalse(didSubmit)
        XCTAssertEqual(vm.score, 0)
        XCTAssertNil(vm.selectedOption)
    }

    func testSubmitOpenWrongAddsWrongAnswer() {
        let vm = makeSUT(words: [("pies", "dog")], isMultipleChoice: false)
        vm.startTest()
        vm.answer = "cat"

        vm.submitOpen()

        XCTAssertEqual(vm.wrongAnswers.count, 1)
        XCTAssertTrue(vm.isFinished)
    }

    func testSubmitOpenWrongKeepsCorrectAnswerVisibleUntilAdvance() {
        let scheduler = ControlledTestAdvanceScheduler()
        let vm = makeSUT(words: [("pies", "dog")], isMultipleChoice: false, scheduler: scheduler)
        vm.startTest()
        vm.answer = "cat"

        vm.submitOpen()

        XCTAssertTrue(vm.showCorrectAnswer)
        scheduler.runPending()
        XCTAssertFalse(vm.showCorrectAnswer)
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
        let vm = makeSUT(words: [("pies", "dog")])
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

    private func makeSUT(
        words: [(String, String)],
        isMultipleChoice: Bool = true,
        scheduler: (any TestAdvanceScheduling)? = nil
    ) -> TestViewModel {
        let set = WordSet(name: "test", words: words.map { Word(polish: $0.0, english: $0.1) })
        let vm = TestViewModel(set: set, scheduler: scheduler ?? ImmediateTestAdvanceScheduler())
        vm.isMultipleChoice = isMultipleChoice
        return vm
    }
}

@MainActor
private final class ControlledTestAdvanceScheduler: TestAdvanceScheduling {
    private var pending: (() -> Void)?

    func schedule(after _: TimeInterval, action: @escaping () -> Void) -> DispatchWorkItem {
        let workItem = DispatchWorkItem(block: {})
        pending = {
            guard !workItem.isCancelled else { return }
            action()
        }
        return workItem
    }

    func runPending() {
        pending?()
        pending = nil
    }
}
