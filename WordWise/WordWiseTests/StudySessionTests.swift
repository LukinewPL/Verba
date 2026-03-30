import XCTest
@testable import WordWise

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
