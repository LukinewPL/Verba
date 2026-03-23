import SwiftUI
import SwiftData
import Observation

@Observable class WordRepository {
    private var modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func fetchAllSets() -> [WordSet] {
        let descriptor = FetchDescriptor<WordSet>(sortBy: [SortDescriptor(\.name)])
        return (try? modelContext.fetch(descriptor)) ?? []
    }
    
    func insertSet(_ set: WordSet) {
        modelContext.insert(set)
        save()
    }
    
    func deleteSet(_ set: WordSet) {
        modelContext.delete(set)
        save()
    }
    
    func fetchFolders() -> [Folder] {
        let descriptor = FetchDescriptor<Folder>(sortBy: [SortDescriptor(\.name)])
        return (try? modelContext.fetch(descriptor)) ?? []
    }
    
    func insertFolder(_ folder: Folder) {
        modelContext.insert(folder)
        save()
    }
    
    func deleteFolder(_ folder: Folder) {
        modelContext.delete(folder)
        save()
    }
    
    func fetchAllSessions() -> [StudySession] {
        let descriptor = FetchDescriptor<StudySession>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        return (try? modelContext.fetch(descriptor)) ?? []
    }
    
    func insertSession(_ session: StudySession) {
        modelContext.insert(session)
        save()
    }
    
    func save() {
        do {
            try modelContext.save()
        } catch {
            print("WordWise: Database save failed — \(error)")
        }
    }
}
