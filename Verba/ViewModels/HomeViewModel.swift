import SwiftUI
import SwiftData
import Observation

@Observable @MainActor class HomeViewModel {
    var sessions: [StudySession] = []
    private var repository: (any WordRepositoryProtocol)?
    
    func setup(repository: any WordRepositoryProtocol) {
        self.repository = repository
        refresh()
    }
    
    func refresh() {
        sessions = repository?.fetchAllSessions() ?? []
    }
    
    var todayWords: Int {
        sessions.filter { Calendar.current.isDateInToday($0.date) }
            .reduce(0) { $0 + $1.wordsStudied }
    }
    
    var streak: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let datesWithStudy = Set(sessions.map { calendar.startOfDay(for: $0.date) })
        
        if datesWithStudy.isEmpty { return 0 }
        
        var currentStreak = 0
        var checkDate = today
        
        if !datesWithStudy.contains(today) {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: today) else { return 0 }
            if !datesWithStudy.contains(yesterday) { return 0 }
            checkDate = yesterday
        }
        
        while datesWithStudy.contains(checkDate) {
            currentStreak += 1
            guard let nextDate = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
            checkDate = nextDate
        }
        return currentStreak
    }
    
    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour >= 5 && hour < 12 { return "good_morning" }
        else if hour >= 12 && hour < 18 { return "good_afternoon" }
        else { return "good_evening" }
    }
}
