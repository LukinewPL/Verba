import SwiftUI
import SwiftData

struct HeatmapView: View {
    let sessions: [StudySession]
    
    init(sessions: [StudySession]) {
        self.sessions = sessions
    }
    
    private var activityByDay: [Date: Int] {
        let calendar = Calendar.current
        var counts: [Date: Int] = [:]
        for session in sessions {
            let day = calendar.startOfDay(for: session.date)
            counts[day, default: 0] += session.wordsStudied
        }
        return counts
    }
    
    private let weeks = 12
    private let daysInWeek = 7
    private let cellSize: CGFloat = 18
    private let spacing: CGFloat = 4
    
    var body: some View {
        VStack {
            Spacer()
            HStack(alignment: .center, spacing: spacing) {
                ForEach(0..<weeks, id: \.self) { week in
                    VStack(spacing: spacing) {
                        ForEach(0..<daysInWeek, id: \.self) { day in
                            let date = dateFor(week: week, day: day)
                            let count = activityByDay[date] ?? 0
                            
                            RoundedRectangle(cornerRadius: 3)
                                .fill(heatmapColor(for: count, isFuture: date > Date()))
                                .frame(width: cellSize, height: cellSize)
                        }
                    }
                }
            }
            Spacer()
        }
        .drawingGroup()
    }
    
    private func dateFor(week: Int, day: Int) -> Date {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Find start of current week
        let weekday = calendar.component(.weekday, from: today)
        let startOfCurrentWeek = calendar.date(byAdding: .day, value: -(weekday - 1), to: today)!
        
        let weeksOffset = -(weeks - 1 - week)
        return calendar.date(byAdding: .day, value: weeksOffset * 7 + day, to: startOfCurrentWeek)!
    }
    
    private func heatmapColor(for count: Int, isFuture: Bool) -> Color {
        if isFuture { return Color.white.opacity(0.05) }
        if count == 0 { return Color.white.opacity(0.15) }
        
        let opacity: Double
        if count < 6 { opacity = 0.3 }
        else if count < 16 { opacity = 0.6 }
        else { opacity = 1.0 }
        
        return Color.glassCyan.opacity(opacity)
    }
}
