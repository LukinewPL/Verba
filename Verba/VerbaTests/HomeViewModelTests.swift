import XCTest
@testable import Verba

@MainActor
final class HomeViewModelTests: XCTestCase {
    var sut: HomeViewModel!
    var repository: MockWordRepository!
    
    override func setUp() {
        super.setUp()
        repository = MockWordRepository()
        sut = HomeViewModel()
        sut.setup(repository: repository)
    }
    
    func testTodayWords() {
        let session1 = StudySession(wordSetID: UUID())
        session1.wordsStudied = 10
        session1.date = Date()
        
        let session2 = StudySession(wordSetID: UUID())
        session2.wordsStudied = 5
        session2.date = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        
        repository.sessions = [session1, session2]
        sut.refresh()
        
        XCTAssertEqual(sut.todayWords, 10)
    }

    func testTodayWordsSumsAllTodaySessions() {
        let s1 = StudySession(wordSetID: UUID())
        s1.wordsStudied = 4
        s1.date = Date()

        let s2 = StudySession(wordSetID: UUID())
        s2.wordsStudied = 9
        s2.date = Date()

        repository.sessions = [s1, s2]
        sut.refresh()

        XCTAssertEqual(sut.todayWords, 13)
    }
    
    func testStreakCalculation() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let dayBefore = calendar.date(byAdding: .day, value: -2, to: today)!
        let gapDay = calendar.date(byAdding: .day, value: -4, to: today)!
        
        let s1 = StudySession(wordSetID: UUID())
        s1.date = today
        let s2 = StudySession(wordSetID: UUID())
        s2.date = yesterday
        let s3 = StudySession(wordSetID: UUID())
        s3.date = dayBefore
        let s4 = StudySession(wordSetID: UUID())
        s4.date = gapDay
        
        repository.sessions = [s1, s2, s3, s4]
        sut.refresh()
        
        XCTAssertEqual(sut.streak, 3)
    }

    func testStreakIsZeroWhenNoSessions() {
        repository.sessions = []
        sut.refresh()

        XCTAssertEqual(sut.streak, 0)
    }

    func testStreakStartsFromYesterdayWhenTodayHasNoSession() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: today)!

        let s1 = StudySession(wordSetID: UUID())
        s1.date = yesterday
        let s2 = StudySession(wordSetID: UUID())
        s2.date = twoDaysAgo

        repository.sessions = [s1, s2]
        sut.refresh()

        XCTAssertEqual(sut.streak, 2)
    }

    func testStreakIsZeroWhenNoTodayAndNoYesterdaySession() {
        let oldSession = StudySession(wordSetID: UUID())
        oldSession.date = Calendar.current.date(byAdding: .day, value: -3, to: Date())!

        repository.sessions = [oldSession]
        sut.refresh()

        XCTAssertEqual(sut.streak, 0)
    }
    
    func testGreeting() {
        // Since greeting depends on Date(), it's hard to test precisely without dependency injection for Date.
        // But we can check it returns one of the expected keys.
        let validGreetings = ["good_morning", "good_afternoon", "good_evening"]
        XCTAssertTrue(validGreetings.contains(sut.greeting))
    }
}
