import XCTest
@testable import WordWise

final class SM2EngineTests: XCTestCase {
    var service = SM2Service()
    
    func testInitialRating() {
        let word = Word(polish: "test", english: "test")
        service.rate(word, quality: 4)
        XCTAssertEqual(word.repetitions, 1)
        XCTAssertEqual(word.interval, 1)
        XCTAssertGreaterThan(word.lastReviewed, Date().addingTimeInterval(-10))
    }
    
    func testSecondRating() {
        let word = Word(polish: "test", english: "test")
        service.rate(word, quality: 5)
        service.rate(word, quality: 5)
        XCTAssertEqual(word.repetitions, 2)
        XCTAssertEqual(word.interval, 6)
    }
    
    func testDifficultyReset() {
        let word = Word(polish: "test", english: "test")
        service.rate(word, quality: 5)
        XCTAssertEqual(word.repetitions, 1)
        service.rate(word, quality: 2)
        XCTAssertEqual(word.repetitions, 0)
        XCTAssertEqual(word.interval, 1)
    }
    
    func testMasteryThreshold() {
        let word = Word(polish: "test", english: "test")
        XCTAssertFalse(word.isMastered)
        for _ in 1...5 { service.rate(word, quality: 4) }
        XCTAssertTrue(word.isMastered)
    }
    
    func testEaseFactorBounds() {
        let word = Word(polish: "test", english: "test")
        for _ in 0...10 { service.rate(word, quality: 0) }
        XCTAssertGreaterThanOrEqual(word.easeFactor, 1.3)
    }
}

@MainActor
final class StudySessionViewModelHintBehaviorTests: XCTestCase {
    func testCorrectAnswerWithHintRequeuesWordAndDoesNotIncreaseScore() {
        let vm = makeSessionViewModel()
        vm.provideHint()
        vm.answer = "dog"

        var successCalled = false
        var failureCalled = false

        vm.checkAnswer(
            onSuccess: { successCalled = true },
            onFailure: { failureCalled = true }
        )

        XCTAssertTrue(successCalled)
        XCTAssertFalse(failureCalled)
        XCTAssertEqual(vm.attemptedCount, 1)
        XCTAssertEqual(vm.correctCount, 0)
        XCTAssertEqual(vm.queue.count, 1)

        vm.nextWord()
        XCTAssertEqual(vm.prompt, "pies")
    }

    func testCorrectAnswerWithoutHintIncreasesScoreAndDoesNotRequeueWord() {
        let vm = makeSessionViewModel()
        vm.answer = "dog"

        vm.checkAnswer(onSuccess: {}, onFailure: {})

        XCTAssertEqual(vm.attemptedCount, 1)
        XCTAssertEqual(vm.correctCount, 1)
        XCTAssertEqual(vm.queue.count, 0)
    }

    private func makeSessionViewModel() -> StudySessionViewModel {
        let set = WordSet(name: "Hint behavior", words: [Word(polish: "pies", english: "dog")])
        let vm = StudySessionViewModel(set: set)
        vm.resetSession()
        return vm
    }
}
