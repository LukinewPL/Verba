import Foundation
import SwiftData
@testable import WordWise

class MockWordRepository: WordRepositoryProtocol {
    var sets: [WordSet] = []
    var folders: [Folder] = []
    var sessions: [StudySession] = []
    var saveCalled = false
    var importCalled = false

    func fetchAllSets() -> [WordSet] { sets }
    func insertSet(_ set: WordSet) { sets.append(set) }
    func deleteSet(_ set: WordSet) { sets.removeAll { $0.id == set.id } }

    func fetchFolders() -> [Folder] { folders }
    func insertFolder(_ folder: Folder) { folders.append(folder) }
    func deleteFolder(_ folder: Folder) { folders.removeAll { $0.id == folder.id } }

    func fetchAllSessions() -> [StudySession] { sessions }
    func insertSession(_ session: StudySession) { sessions.append(session) }

    func importFile(url: URL, swapColumns: Bool, lang1: String?, lang2: String?) throws { importCalled = true }

    func getParsedRows(url: URL) throws -> (name: String, rows: [[String]]) {
        (url.deletingPathExtension().lastPathComponent, [])
    }

    func save() { saveCalled = true }
}
