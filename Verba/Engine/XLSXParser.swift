import Foundation
import SwiftData

struct XLSXParser {
    static func parse(url: URL) throws -> [[String]] {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let tempFile = tempDir.appendingPathComponent("import.xlsx")
        try FileManager.default.copyItem(at: url, to: tempFile)

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
        process.arguments = ["-o", tempFile.path, "-d", tempDir.path]
        try process.run()
        process.waitUntilExit()

        // 1. Parse Shared Strings
        var sharedStrings: [String] = []
        let sharedStringsURL = tempDir.appendingPathComponent("xl/sharedStrings.xml")
        if let sharedData = try? Data(contentsOf: sharedStringsURL),
           let xml = try? XMLDocument(data: sharedData, options: []) {
            let siNodes = (try? xml.nodes(forXPath: ".//si")) ?? []
            for node in siNodes {
                var text = ""
                // XLSX can have multiple <t> nodes for formatted text
                if let tNodes = try? node.nodes(forXPath: ".//t") {
                    text = tNodes.compactMap { $0.stringValue }.joined()
                }
                sharedStrings.append(text)
            }
        }

        // 2. Parse Sheet1
        var rows: [[String]] = []
        let sheetURL = tempDir.appendingPathComponent("xl/worksheets/sheet1.xml")
        if let sheetData = try? Data(contentsOf: sheetURL),
           let xml = try? XMLDocument(data: sheetData, options: []) {
            let rowNodes = (try? xml.nodes(forXPath: ".//row")) ?? []
            for rowNode in rowNodes {
                guard let cellNodes = try? rowNode.nodes(forXPath: "./c") else { continue }
                
                var wordA = "", wordB = ""
                for cell in cellNodes as! [XMLElement] {
                    let colRef = cell.attribute(forName: "r")?.stringValue ?? ""
                    let col = colRef.trimmingCharacters(in: .decimalDigits)
                    let type = cell.attribute(forName: "t")?.stringValue ?? ""
                    let value = cell.elements(forName: "v").first?.stringValue ?? ""
                    
                    var cellValue = value
                    if type == "s", let idx = Int(value), idx < sharedStrings.count {
                        cellValue = sharedStrings[idx]
                    }
                    
                    if col == "A" { wordA = cellValue }
                    if col == "B" { wordB = cellValue }
                }
                
                let cleanA = sanitize(wordA)
                let cleanB = sanitize(wordB)
                if !cleanA.isEmpty && !cleanB.isEmpty {
                    rows.append([cleanB, cleanA]) // [Polish, English]
                }
            }
        }
        return rows
    }
    
    static func sanitize(_ text: String) -> String {
        return text
            .replacingOccurrences(of: "\u{00A0}", with: " ")
            .replacingOccurrences(of: "\u{200B}", with: "")
            .replacingOccurrences(of: "\u{FEFF}", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.joined(separator: " ")
    }
}

