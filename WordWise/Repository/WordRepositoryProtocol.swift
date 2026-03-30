import Foundation
import SwiftData

protocol WordRepositoryProtocol: AnyObject {
    func fetchAllSets() -> [WordSet]
    func insertSet(_ set: WordSet)
    func deleteSet(_ set: WordSet)
    
    func fetchFolders() -> [Folder]
    func insertFolder(_ folder: Folder)
    func deleteFolder(_ folder: Folder)
    
    func fetchAllSessions() -> [StudySession]
    func insertSession(_ session: StudySession)
    
    func importFile(url: URL, swapColumns: Bool, lang1: String?, lang2: String?) throws
    func getParsedRows(url: URL) throws -> (name: String, rows: [[String]])
    
    func save()
}
