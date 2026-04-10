import Foundation
import SwiftData
@testable import Verba

class MockWordRepository: WordRepositoryProtocol {
    var sets: [WordSet] = []
    var folders: [Folder] = []
    var sessions: [StudySession] = []
    var saveCalled = false
    var saveCallCount = 0
    var importCalled = false
    var importError: Error?
    var importInvocations: [(url: URL, swapColumns: Bool, lang1: String?, lang2: String?)] = []
    var parsedRowsResult: (name: String, rows: [[String]])?
    var parsedRowsError: Error?
    var resetAllDataCalled = false

    func fetchAllSets() -> [WordSet] { sets }
    func insertSet(_ set: WordSet) { sets.append(set) }
    func deleteSet(_ set: WordSet) { sets.removeAll { $0.id == set.id } }

    func fetchFolders() -> [Folder] { folders }
    func insertFolder(_ folder: Folder) { folders.append(folder) }
    func deleteFolder(_ folder: Folder) { folders.removeAll { $0.id == folder.id } }

    func fetchAllSessions() -> [StudySession] { sessions }
    func insertSession(_ session: StudySession) { sessions.append(session) }

    func importFile(url: URL, swapColumns: Bool, lang1: String?, lang2: String?) throws {
        importCalled = true
        importInvocations.append((url, swapColumns, lang1, lang2))
        if let importError {
            throw importError
        }
    }

    func getParsedRows(url: URL) throws -> (name: String, rows: [[String]]) {
        if let parsedRowsError {
            throw parsedRowsError
        }
        if let parsedRowsResult {
            return parsedRowsResult
        }
        return (url.deletingPathExtension().lastPathComponent, [])
    }

    func resetAllData() {
        resetAllDataCalled = true
        sets.removeAll()
        folders.removeAll()
        sessions.removeAll()
    }

    func save() {
        saveCalled = true
        saveCallCount += 1
    }
}
