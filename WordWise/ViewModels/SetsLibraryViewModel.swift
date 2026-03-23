import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import Observation

@Observable class SetsLibraryViewModel {
    var folders: [Folder] = []
    var allSets: [WordSet] = []
    
    var showFilePicker = false
    var importError: String? = nil
    var showError = false
    var showNewFolderAlert = false
    var dragOverFolderID: UUID? = nil
    var dragOverUnfiled = false
    var newFolderName: String = ""
    var expandedFolders: Set<UUID> = []
    var renamingFolderID: UUID? = nil
    var folderRenameText: String = ""
    
    private var repository: WordRepository?
    
    func setup(repository: WordRepository) {
        self.repository = repository
        refresh()
    }
    
    func refresh() {
        guard let repository = repository else { return }
        folders = repository.fetchFolders()
        allSets = repository.fetchAllSets()
    }
    
    var ungroupedSets: [WordSet] {
        allSets.filter { $0.folder == nil }
    }
    
    func handleDrop(ids: [String], to folder: Folder?) -> Bool {
        for idString in ids {
            if let set = allSets.first(where: { $0.id.uuidString == idString }) {
                set.folder = folder
            }
        }
        repository?.save()
        withAnimation(.easeInOut(duration: 0.25)) {
            refresh()
        }
        return true
    }
    
    func createFolder() {
        let folder = Folder(name: newFolderName)
        repository?.insertFolder(folder)
        newFolderName = ""
        refresh()
    }
    
    func renameFolder(_ folder: Folder, to newName: String) {
        folder.name = newName
        repository?.save()
        refresh()
    }
    
    func deleteFolder(_ folder: Folder) {
        repository?.deleteFolder(folder)
        refresh()
    }
    
    func importFile(url: URL, context: ModelContext) {
        do {
            try ImportEngine.importFile(url: url, context: context, existingSets: allSets)
            refresh()
        } catch {
            importError = error.localizedDescription
            showError = true
        }
    }
    
    var allowedContentTypes: [UTType] {
        var types: [UTType] = [.plainText, .commaSeparatedText, .spreadsheet]
        if let xlsx = UTType(filenameExtension: "xlsx") {
            types.append(xlsx)
        }
        return types
    }
}
