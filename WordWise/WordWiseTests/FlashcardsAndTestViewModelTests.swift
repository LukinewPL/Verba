import XCTest
@testable import WordWise

@MainActor
final class TestViewModelTests: XCTestCase {
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
