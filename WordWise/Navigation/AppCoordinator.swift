import SwiftUI
import Observation

enum AppScreen: Hashable {
    case home
    case library
    case setDetail(WordSet)
    case studySession(WordSet)
    case speedRound(WordSet)
    case test(WordSet)
    case settings
}

@Observable class AppCoordinator {
    var path = NavigationPath()
    var selectedTab: Tab = .home
    
    enum Tab: Int, Hashable {
        case home, library, settings
    }
    
    func navigate(to screen: AppScreen) {
        path.append(screen)
    }
    
    func pop() {
        path.removeLast()
    }
    
    func popToRoot() {
        path = NavigationPath()
    }
}
