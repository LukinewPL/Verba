import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import Observation

@Observable @MainActor class SetsLibraryViewModel {
    var folders: [Folder] = []
    var allSets: [WordSet] = []

    var showFilePicker = false
    var importError: String? = nil
    var showError = false
    var showNewFolderAlert = false
    var dragOverFolderID: UUID? = nil
    var dragOverUnfiled = false
    var newFolderName: String = ""
    var collapsedFolderIDs: Set<UUID> = []
    var renamingFolderID: UUID? = nil
    var folderRenameText: String = ""
    var importConfig: ImportConfiguration? = nil

    private var repository: (any WordRepositoryProtocol)?

    func setup(repository: any WordRepositoryProtocol) {
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
        let trimmedName = sanitizeFolderName(newFolderName)
        guard !trimmedName.isEmpty else { return }
        guard !folders.contains(where: { $0.name.caseInsensitiveCompare(trimmedName) == .orderedSame }) else {
            return
        }

        let folder = Folder(name: trimmedName)
        repository?.insertFolder(folder)
        newFolderName = ""
        refresh()
    }

    func renameFolder(_ folder: Folder, to newName: String) {
        let trimmedName = sanitizeFolderName(newName)
        guard !trimmedName.isEmpty else { return }
        guard !folders.contains(where: { $0.id != folder.id && $0.name.caseInsensitiveCompare(trimmedName) == .orderedSame }) else {
            return
        }

        folder.name = trimmedName
        repository?.save()
        refresh()
    }

    func deleteFolder(_ folder: Folder) {
        repository?.deleteFolder(folder)
        refresh()
    }

    func startImport(url: URL) {
        do {
            guard let repository = repository else { return }
            let (name, rows) = try repository.getParsedRows(url: url)
            let (l1, l2) = ImportService().detectLanguages(for: rows)

            self.importConfig = ImportConfiguration(
                url: url,
                name: name,
                rows: rows,
                lang1: l1,
                lang2: l2
            )
        } catch {
            importError = error.localizedDescription
            showError = true
        }
    }

    func confirmImport(swap: Bool) {
        guard let config = importConfig else { return }
        do {
            try repository?.importFile(url: config.url, swapColumns: swap, lang1: config.lang1, lang2: config.lang2)
            importConfig = nil
            refresh()
        } catch {
            importConfig = nil
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

    private func sanitizeFolderName(_ name: String) -> String {
        name
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
}
