import SwiftUI
import SwiftData

// MARK: - App

@main struct WordWiseApp: App {
    @State private var languageManager = LanguageManager.shared
    @State private var coordinator = AppCoordinator()
    
    let container: ModelContainer
    
    init() {
        do {
            container = try ModelContainer(for: WordSet.self, Word.self, StudySession.self, Folder.self)
        } catch {
            fatalError("Could not initialize ModelContainer")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            MainCoordinatorView()
                .preferredColorScheme(.dark)
                .environment(languageManager)
                .environment(coordinator)
                .environment(WordRepository(modelContext: container.mainContext))
        }
        .modelContainer(container)
        .windowResizability(.contentMinSize)
        .defaultSize(width: 800, height: 600)
    }
}
