import SwiftUI
import Observation

enum AppScreen: Hashable {
    case home
    case library
    case setDetail(WordSet)
    case studySession(WordSet)
    case speedRound(WordSet)
    case test(WordSet)
    case flashcards(WordSet)
    case settings
}

@Observable @MainActor class AppCoordinator {
    var path: [AppScreen] = []
    var selectedTab: Tab = .home
    
    enum Tab: Int, Hashable {
        case home, library, settings
    }
    
    func navigate(to screen: AppScreen) {
        path.append(screen)
    }
    
    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }
    
    func popToRoot() {
        path.removeAll()
    }
}
