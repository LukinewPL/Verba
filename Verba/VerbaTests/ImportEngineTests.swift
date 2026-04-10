import Foundation
import SwiftData
import XCTest
@testable import Verba

@MainActor
final class ImportServiceTests: XCTestCase {
    var container: ModelContainer!
    var context: ModelContext!
    var service: ImportService!

    override func setUp() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(
            for: WordSet.self,
            Word.self,
            Folder.self,
            StudySession.self,
            configurations: config
        )
        context = ModelContext(container)
        service = ImportService()
    }

    func testImportFileParsesTabSeparatedRows() throws {
        let url = try makeTempFile(name: UUID().uuidString, ext: "txt", content: "dog\tpies\ncat\tkot")
        defer { try? FileManager.default.removeItem(at: url) }

        try service.importFile(url: url, context: context, existingSets: [])

        let sets = try context.fetch(FetchDescriptor<WordSet>())
        XCTAssertEqual(sets.count, 1)
        XCTAssertEqual(sets.first?.words.count, 2)
        XCTAssertEqual(sets.first?.words.first(where: { $0.polish == "dog" })?.english, "pies")
    }

    func testImportFileParsesSemicolonSeparatedRows() throws {
        let url = try makeTempFile(name: UUID().uuidString, ext: "txt", content: "sun;slonce\nmoon;ksiezyc")
        defer { try? FileManager.default.removeItem(at: url) }

        try service.importFile(url: url, context: context, existingSets: [])

        let sets = try context.fetch(FetchDescriptor<WordSet>())
        XCTAssertEqual(sets.first?.words.count, 2)
        XCTAssertTrue(sets.first?.words.contains(where: { $0.polish == "sun" && $0.english == "slonce" }) == true)
    }

    func testImportFileParsesEqualsSeparatedRows() throws {
        let url = try makeTempFile(name: UUID().uuidString, ext: "txt", content: "red=czewony\nblue=niebieski")
        defer { try? FileManager.default.removeItem(at: url) }

        try service.importFile(url: url, context: context, existingSets: [])

        let sets = try context.fetch(FetchDescriptor<WordSet>())
        XCTAssertEqual(sets.first?.words.count, 2)
        XCTAssertEqual(sets.first?.words.first(where: { $0.polish == "red" })?.english, "czewony")
    }

    func testImportFileSkipsInvalidRows() throws {
        let content = """
        valid\tpoprawny
        only-one-column
        too\tmany\tcolumns
        \t
        """
        let url = try makeTempFile(name: UUID().uuidString, ext: "txt", content: content)
        defer { try? FileManager.default.removeItem(at: url) }

        try service.importFile(url: url, context: context, existingSets: [])

        let sets = try context.fetch(FetchDescriptor<WordSet>())
        XCTAssertEqual(sets.first?.words.count, 1)
        XCTAssertEqual(sets.first?.words.first?.polish, "valid")
    }

    func testImportFileReplacesExistingSetWhenMergeDisabled() throws {
        let existing = WordSet(name: "animals", words: [Word(polish: "old", english: "stary")])
        context.insert(existing)
        try context.save()

        let url = try makeTempFile(name: "animals", ext: "txt", content: "dog\tpies")
        defer { try? FileManager.default.removeItem(at: url) }

        try service.importFile(url: url, context: context, existingSets: [existing], mergeExisting: false)

        let sets = try context.fetch(FetchDescriptor<WordSet>())
        XCTAssertEqual(sets.count, 1)
        XCTAssertEqual(sets.first?.words.count, 1)
        XCTAssertEqual(sets.first?.words.first?.polish, "dog")
    }

    func testImportFileMergesAndSkipsDuplicatesWhenMergeEnabled() throws {
        let existing = WordSet(name: "verbs", words: [Word(polish: "go", english: "isc")])
        context.insert(existing)
        try context.save()

        let url = try makeTempFile(name: "verbs", ext: "txt", content: "go\tisc\nrun\tbiegac")
        defer { try? FileManager.default.removeItem(at: url) }

        try service.importFile(url: url, context: context, existingSets: [existing], mergeExisting: true)

        let sets = try context.fetch(FetchDescriptor<WordSet>())
        let verbs = try XCTUnwrap(sets.first)
        XCTAssertEqual(verbs.words.count, 2)
        XCTAssertTrue(verbs.words.contains(where: { $0.polish == "go" && $0.english == "isc" }))
        XCTAssertTrue(verbs.words.contains(where: { $0.polish == "run" && $0.english == "biegac" }))
    }

    func testImportFileSwapColumnsAndLanguageMapping() throws {
        let url = try makeTempFile(name: UUID().uuidString, ext: "txt", content: "apple\tjablko")
        defer { try? FileManager.default.removeItem(at: url) }

        try service.importFile(
            url: url,
            context: context,
            existingSets: [],
            swapColumns: true,
            lang1: "en",
            lang2: "pl"
        )

        let sets = try context.fetch(FetchDescriptor<WordSet>())
        let set = try XCTUnwrap(sets.first)
        let word = try XCTUnwrap(set.words.first)
        XCTAssertEqual(word.polish, "jablko")
        XCTAssertEqual(word.english, "apple")
        XCTAssertEqual(set.sourceLanguage, "pl")
        XCTAssertEqual(set.targetLanguage, "en")
    }

    func testImportFileThrowsWhenNoValidRowsAndMergeDisabled() throws {
        let url = try makeTempFile(name: UUID().uuidString, ext: "txt", content: "invalid-row-without-separator")
        defer { try? FileManager.default.removeItem(at: url) }

        XCTAssertThrowsError(
            try service.importFile(url: url, context: context, existingSets: [], mergeExisting: false)
        )
    }

    func testImportFileDoesNotThrowWhenNoValidRowsAndMergeEnabled() throws {
        let existing = WordSet(name: "empty")
        context.insert(existing)
        try context.save()

        let url = try makeTempFile(name: "empty", ext: "txt", content: "invalid-row-without-separator")
        defer { try? FileManager.default.removeItem(at: url) }

        XCTAssertNoThrow(
            try service.importFile(url: url, context: context, existingSets: [existing], mergeExisting: true)
        )
    }

    func testGetParsedRowsReturnsNameAndRows() throws {
        let url = try makeTempFile(name: "my_words_set", ext: "txt", content: "home\tdom\nbook\tksiazka")
        defer { try? FileManager.default.removeItem(at: url) }

        let result = try service.getParsedRows(from: url)
        XCTAssertEqual(result.name, "my_words_set")
        XCTAssertEqual(result.rows.count, 2)
        XCTAssertEqual(result.rows.first?[0], "home")
        XCTAssertEqual(result.rows.first?[1], "dom")
    }

    func testDetectLanguagesReturnsAtLeastOneForStrongSignal() {
        let rows = [
            ["hello world and nice weather", "to jest zdanie po polsku z diakrytyka i sensem"],
            ["good morning have a great day", "dziekuje bardzo za pomoc i wsparcie"]
        ]
        let detected = service.detectLanguages(for: rows)
        XCTAssertTrue(detected.lang1 != nil || detected.lang2 != nil)
    }

    func testDetectLanguagesMayReturnAmbiguousForSameLanguageColumns() {
        let rows = [
            ["this is all english text in first column", "another english sentence in second column"],
            ["simple words only for language detector", "more english content for ambiguity"]
        ]
        let detected = service.detectLanguages(for: rows)
        XCTAssertTrue(detected.lang1 == nil || detected.lang2 == nil || detected.lang1 != detected.lang2)
    }

    private func makeTempFile(name: String, ext: String, content: String) throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(name).\(ext)")
        try content.write(to: url, atomically: true, encoding: .utf8)
        return url
    }
}

@MainActor
final class WordRepositoryTests: XCTestCase {
    var container: ModelContainer!
    var context: ModelContext!
    var repository: WordRepository!

    override func setUp() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(
            for: WordSet.self,
            Word.self,
            Folder.self,
            StudySession.self,
            configurations: config
        )
        context = ModelContext(container)
        repository = WordRepository(modelContext: context)
    }

    func testInsertSetAndFetchSortedByName() {
        repository.insertSet(WordSet(name: "Zoo"))
        repository.insertSet(WordSet(name: "Alpha"))

        let fetched = repository.fetchAllSets()
        XCTAssertEqual(fetched.map(\.name), ["Alpha", "Zoo"])
    }

    func testDeleteSetRemovesItFromStorage() {
        let set = WordSet(name: "ToDelete")
        repository.insertSet(set)

        repository.deleteSet(set)

        let fetched = repository.fetchAllSets()
        XCTAssertFalse(fetched.contains(where: { $0.id == set.id }))
    }

    func testInsertAndDeleteFolder() {
        let folder = Folder(name: "Folder A")
        repository.insertFolder(folder)
        XCTAssertEqual(repository.fetchFolders().count, 1)

        repository.deleteFolder(folder)
        XCTAssertTrue(repository.fetchFolders().isEmpty)
    }

    func testInsertSessionAndFetchOrderDescendingByDate() {
        let older = StudySession(wordSetID: UUID())
        older.date = Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date()
        older.wordsStudied = 7
        repository.insertSession(older)

        let newer = StudySession(wordSetID: UUID())
        newer.date = Date()
        newer.wordsStudied = 3
        repository.insertSession(newer)

        let sessions = repository.fetchAllSessions()
        XCTAssertEqual(sessions.count, 2)
        XCTAssertEqual(sessions.first?.id, newer.id)
    }
}
