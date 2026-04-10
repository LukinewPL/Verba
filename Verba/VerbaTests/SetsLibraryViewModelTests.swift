import XCTest
@testable import Verba

@MainActor
final class SetsLibraryViewModelTests: XCTestCase {
    var sut: SetsLibraryViewModel!
    var repository: MockWordRepository!
    
    override func setUp() {
        super.setUp()
        repository = MockWordRepository()
        sut = SetsLibraryViewModel()
        sut.setup(repository: repository)
    }
    
    func testCreateFolder() {
        sut.newFolderName = "Test Folder"
        sut.createFolder()
        
        XCTAssertEqual(repository.folders.count, 1)
        XCTAssertEqual(repository.folders.first?.name, "Test Folder")
    }

    func testCreateFolderTrimsWhitespaceAndCollapsesInternalSpaces() {
        sut.newFolderName = "   New    Folder   Name   "
        sut.createFolder()

        XCTAssertEqual(repository.folders.first?.name, "New Folder Name")
    }

    func testCreateFolderRejectsCaseInsensitiveDuplicates() {
        repository.folders = [Folder(name: "Travel")]
        sut.refresh()

        sut.newFolderName = " travel "
        sut.createFolder()

        XCTAssertEqual(repository.folders.count, 1)
    }
    
    func testDeleteFolder() {
        let folder = Folder(name: "To delete")
        repository.insertFolder(folder)
        sut.refresh()
        
        sut.deleteFolder(folder)
        XCTAssertTrue(repository.folders.isEmpty)
    }
    
    func testRenameFolder() {
        let folder = Folder(name: "Old")
        repository.insertFolder(folder)
        sut.refresh()
        
        sut.renameFolder(folder, to: "New")
        XCTAssertEqual(folder.name, "New")
    }

    func testRenameFolderRejectsCaseInsensitiveDuplicates() {
        let first = Folder(name: "First")
        let second = Folder(name: "Second")
        repository.folders = [first, second]
        sut.refresh()

        sut.renameFolder(second, to: " first ")

        XCTAssertEqual(second.name, "Second")
    }
    
    func testHandleDrop() {
        let set = WordSet(name: "Drag Set")
        repository.sets = [set]
        sut.refresh()
        
        let folder = Folder(name: "Target")
        repository.folders = [folder]
        
        _ = sut.handleDrop(ids: [set.id.uuidString], to: folder)
        
        XCTAssertEqual(set.folder?.id, folder.id)
    }

    func testHandleDropToNilUnassignsFolder() {
        let folder = Folder(name: "A")
        let set = WordSet(name: "Drag Set")
        set.folder = folder
        repository.sets = [set]
        sut.refresh()

        _ = sut.handleDrop(ids: [set.id.uuidString], to: nil)

        XCTAssertNil(set.folder)
        XCTAssertTrue(repository.saveCalled)
    }
    
    func testUngroupedSets() {
        let set1 = WordSet(name: "In Folder")
        let folder = Folder(name: "F")
        set1.folder = folder
        
        let set2 = WordSet(name: "Loose")
        repository.sets = [set1, set2]
        sut.refresh()
        
        XCTAssertEqual(sut.ungroupedSets.count, 1)
        XCTAssertEqual(sut.ungroupedSets.first?.name, "Loose")
    }

    func testStartImportBuildsConfigurationFromParsedRows() {
        let url = URL(fileURLWithPath: "/tmp/animals.txt")
        repository.parsedRowsResult = (
            name: "animals",
            rows: [
                ["dog", "pies"],
                ["cat", "kot"]
            ]
        )

        sut.startImport(url: url)

        XCTAssertEqual(sut.importConfig?.name, "animals")
        XCTAssertEqual(sut.importConfig?.rows.count, 2)
        XCTAssertFalse(sut.showError)
    }

    func testStartImportShowsErrorWhenParsingFails() {
        struct ParsingError: LocalizedError {
            var errorDescription: String? { "parse failed" }
        }
        repository.parsedRowsError = ParsingError()

        sut.startImport(url: URL(fileURLWithPath: "/tmp/bad.txt"))

        XCTAssertTrue(sut.showError)
        XCTAssertEqual(sut.importError, "parse failed")
    }

    func testConfirmImportCallsRepositoryAndClearsConfig() {
        let url = URL(fileURLWithPath: "/tmp/animals.txt")
        sut.importConfig = ImportConfiguration(
            url: url,
            name: "animals",
            rows: [["dog", "pies"]],
            lang1: "en",
            lang2: "pl"
        )

        sut.confirmImport(swap: true)

        XCTAssertTrue(repository.importCalled)
        XCTAssertNil(sut.importConfig)
        XCTAssertEqual(repository.importInvocations.first?.swapColumns, true)
        XCTAssertEqual(repository.importInvocations.first?.lang1, "en")
        XCTAssertEqual(repository.importInvocations.first?.lang2, "pl")
    }

    func testConfirmImportShowsErrorWhenRepositoryThrows() {
        struct ImportFailure: LocalizedError {
            var errorDescription: String? { "import failed" }
        }
        repository.importError = ImportFailure()
        sut.importConfig = ImportConfiguration(
            url: URL(fileURLWithPath: "/tmp/fail.txt"),
            name: "fail",
            rows: [["a", "b"]],
            lang1: nil,
            lang2: nil
        )

        sut.confirmImport(swap: false)

        XCTAssertNil(sut.importConfig)
        XCTAssertTrue(sut.showError)
        XCTAssertEqual(sut.importError, "import failed")
    }
}
