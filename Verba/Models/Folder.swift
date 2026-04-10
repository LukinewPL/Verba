import Foundation
import SwiftData

@Model final class Folder {
    var id: UUID = UUID()
    var name: String = ""
    @Relationship(deleteRule: .nullify, inverse: \WordSet.folder)
    var sets: [WordSet] = []

    init(name: String) {
        self.id = UUID()
        self.name = name
        self.sets = []
    }
}
