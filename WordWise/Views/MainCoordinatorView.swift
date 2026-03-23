import SwiftUI

// MARK: - View

struct MainCoordinatorView: View {
    @Environment(LanguageManager.self) private var lm
    @Environment(AppCoordinator.self) private var coordinator
    @State private var errorHandler = ErrorHandler.shared

    var body: some View {
        @Bindable var coordinator = coordinator
        @Bindable var eh = errorHandler
        
        NavigationSplitView {
            List(selection: $coordinator.selectedTab) {
                NavigationLink(value: AppCoordinator.Tab.home) {
                    Label(lm.t("home"), systemImage: "house")
                }
                NavigationLink(value: AppCoordinator.Tab.library) {
                    Label(lm.t("sets_library"), systemImage: "books.vertical")
                }
                NavigationLink(value: AppCoordinator.Tab.settings) {
                    Label(lm.t("settings"), systemImage: "gearshape")
                }
            }
            .navigationTitle(lm.t("WordWise"))
        } detail: {
            ZStack {
                LinearGradient(
                    colors: [.deepNavy, .glassBack],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                Group {
                    switch coordinator.selectedTab {
                    case .home:
                        HomeView()
                    case .library:
                        SetsLibraryView()
                    case .settings:
                        SettingsView()
                    }
                }
            }
        }
        .frame(minWidth: 700, minHeight: 500)
        .alert(lm.t("error_occurred"), isPresented: $eh.showErrorMessage) {
            Button(lm.t("ok"), role: .cancel) { eh.clear() }
        } message: {
            if let error = eh.currentError {
                Text(error.localizedDescription)
            }
        }
    }
}
