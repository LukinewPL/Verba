import Foundation

struct ImportConfiguration: Identifiable {
    let id = UUID()
    let url: URL
    let name: String
    let rows: [[String]]
    var lang1: String?
    var lang2: String?
    var swapColumns: Bool = false
}
