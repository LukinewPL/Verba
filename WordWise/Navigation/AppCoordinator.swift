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
    private(set) var focusedModeDepth: Int = 0
    private let animationSpeedKey = "animationSpeed"

    var isInFocusedMode: Bool {
        focusedModeDepth > 0
    }

    enum Tab: Int, Hashable {
        case home, library, settings
    }

    private func performNavigationUpdate(baseDuration: Double = 0.2, _ updates: () -> Void) {
        let defaultSpeed = 1.0
        let hasStoredValue = UserDefaults.standard.object(forKey: animationSpeedKey) != nil
        let effectiveSpeed = hasStoredValue
            ? UserDefaults.standard.double(forKey: animationSpeedKey)
            : defaultSpeed

        guard effectiveSpeed > 0 else {
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction, updates)
            return
        }

        let adjustedDuration = max(0.12, baseDuration / effectiveSpeed)
        withAnimation(.snappy(duration: adjustedDuration), updates)
    }

    func navigate(to screen: AppScreen) {
        performNavigationUpdate(baseDuration: 0.22) {
            path.append(screen)
        }
    }

    func pop() {
        guard !path.isEmpty else { return }
        performNavigationUpdate {
            path.removeLast()
        }
    }

    func popToRoot() {
        performNavigationUpdate {
            path.removeAll()
        }
    }

    func selectTab(_ tab: Tab) {
        performNavigationUpdate {
            selectedTab = tab
            path.removeAll()
        }
    }

    func enterFocusedMode() {
        focusedModeDepth += 1
    }

    func exitFocusedMode() {
        focusedModeDepth = max(0, focusedModeDepth - 1)
    }
}
