import XCTest
@testable import Verba

final class StudySessionTests: XCTestCase {
    func testSessionInit() {
        let id = UUID()
        let session = StudySession(wordSetID: id)
        XCTAssertEqual(session.wordSetID, id)
        XCTAssertEqual(session.wordsStudied, 0)
        XCTAssertEqual(session.correctAnswers, 0)
        XCTAssertGreaterThan(session.date, Date().addingTimeInterval(-10))
    }
    
    func testAccuracy() {
        let session = StudySession(wordSetID: UUID())
        session.wordsStudied = 10
        session.correctAnswers = 7
        // Accuracy isn't a property yet, but we can verify it's valid if we add it.
        XCTAssertEqual(Double(session.correctAnswers) / Double(session.wordsStudied), 0.7)
    }

    func testSessionHasUniqueIDByDefault() {
        let first = StudySession(wordSetID: UUID())
        let second = StudySession(wordSetID: UUID())

        XCTAssertNotEqual(first.id, second.id)
    }
}

@MainActor
final class AppCoordinatorTests: XCTestCase {
    func testNavigatePushesScreenOnPath() {
        let coordinator = AppCoordinator()
        let set = WordSet(name: "A")

        coordinator.navigate(to: .setDetail(set))

        XCTAssertEqual(coordinator.path.count, 1)
    }

    func testPopDoesNothingForEmptyPath() {
        let coordinator = AppCoordinator()

        coordinator.pop()

        XCTAssertTrue(coordinator.path.isEmpty)
    }

    func testSelectTabResetsPathAndChangesTab() {
        let coordinator = AppCoordinator()
        coordinator.path = [.home, .library]

        coordinator.selectTab(.settings)

        XCTAssertEqual(coordinator.selectedTab, .settings)
        XCTAssertTrue(coordinator.path.isEmpty)
    }

    func testFocusedModeDepthNeverDropsBelowZero() {
        let coordinator = AppCoordinator()
        coordinator.enterFocusedMode()
        coordinator.enterFocusedMode()
        coordinator.exitFocusedMode()
        coordinator.exitFocusedMode()
        coordinator.exitFocusedMode()

        XCTAssertFalse(coordinator.isInFocusedMode)
    }
}

final class MainCoordinatorLayoutTests: XCTestCase {
    func testSidebarUsesFixedWidthMetrics() {
        XCTAssertEqual(MainCoordinatorLayoutMetrics.sidebar.min, 280)
        XCTAssertEqual(MainCoordinatorLayoutMetrics.sidebar.ideal, 280)
        XCTAssertEqual(MainCoordinatorLayoutMetrics.sidebar.max, 280)
    }
}

@MainActor
final class SpeedRoundViewModelTests: XCTestCase {
    func testStartGameUsesDueReviewedWordsWhenAvailable() {
        let due = Word(polish: "pies", english: "dog")
        due.lastReviewed = Date().addingTimeInterval(-3_600)
        due.nextReview = Date().addingTimeInterval(-300)

        let future = Word(polish: "kot", english: "cat")
        future.lastReviewed = Date().addingTimeInterval(-3_600)
        future.nextReview = Date().addingTimeInterval(3_600)

        let newWord = Word(polish: "ptak", english: "bird")
        let set = WordSet(name: "speed", words: [due, future, newWord])
        let vm = SpeedRoundViewModel(set: set)

        vm.startGame()

        XCTAssertEqual(vm.current?.id, due.id)
        XCTAssertTrue(vm.queue.isEmpty)
    }

    func testStartGameFallsBackToNewWordsWhenNoDueReviewedWordsExist() {
        let future = Word(polish: "kot", english: "cat")
        future.lastReviewed = Date().addingTimeInterval(-3_600)
        future.nextReview = Date().addingTimeInterval(3_600)

        let newWord = Word(polish: "ptak", english: "bird")
        let set = WordSet(name: "speed", words: [future, newWord])
        let vm = SpeedRoundViewModel(set: set)

        vm.startGame()

        XCTAssertEqual(vm.current?.id, newWord.id)
        XCTAssertTrue(vm.queue.isEmpty)
    }

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
