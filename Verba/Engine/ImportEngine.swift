import Foundation
import SwiftData
import UniformTypeIdentifiers
import NaturalLanguage

class ImportService {
    func getParsedRows(from url: URL) throws -> (name: String, rows: [[String]]) {
        let access = url.startAccessingSecurityScopedResource()
        defer { if access { url.stopAccessingSecurityScopedResource() } }
        
        let name = url.deletingPathExtension().lastPathComponent
        let rows: [[String]]
        if url.pathExtension.lowercased() == "xlsx" {
            rows = try XLSXParser.parse(url: url)
        } else {
            rows = try parseTXT(url: url)
        }
        return (name, rows)
    }

    func detectLanguages(for rows: [[String]]) -> (lang1: String?, lang2: String?) {
        var col1Text = ""
        var col2Text = ""
        
        // Use a wider sample for better detection quality on short datasets.
        for row in rows.prefix(30) {
            if row.count >= 1 { col1Text += row[0] + " " }
            if row.count >= 2 { col2Text += row[1] + " " }
        }

        let first = detectDominantLanguage(in: col1Text)
        let second = detectDominantLanguage(in: col2Text)
        
        var lang1 = first?.code
        var lang2 = second?.code
        
        // If both columns resolve to the same language with similar confidence,
        // treat detection as ambiguous so the user can confirm manually.
        if lang1 == lang2, let first, let second {
            if abs(first.confidence - second.confidence) < 0.15 {
                lang1 = nil
                lang2 = nil
            } else if first.confidence > second.confidence {
                lang2 = nil
            } else {
                lang1 = nil
            }
        }

        return (lang1, lang2)
    }

    func importFile(url: URL, context: ModelContext, existingSets: [WordSet], mergeExisting: Bool = false, swapColumns: Bool = false, lang1: String? = nil, lang2: String? = nil) throws {
        let access = url.startAccessingSecurityScopedResource()
        defer { if access { url.stopAccessingSecurityScopedResource() } }
        
        let name = url.deletingPathExtension().lastPathComponent
        let wset = getOrCreateSet(name: name, context: context, existingSets: existingSets, merge: mergeExisting)
        
        // Update languages if detected
        if let l1 = lang1, let l2 = lang2 {
            wset.sourceLanguage = swapColumns ? l2 : l1
            wset.targetLanguage = swapColumns ? l1 : l2
        }
        
        let rows: [[String]]
        if url.pathExtension.lowercased() == "xlsx" {
            rows = try XLSXParser.parse(url: url)
        } else {
            rows = try parseTXT(url: url)
        }
        
        var importedCount = 0
        for p in rows {
            if p.count == 2 {
                let first = swapColumns ? p[1] : p[0]
                let second = swapColumns ? p[0] : p[1]
                
                // For now, mapping to polish/english fields
                // User can define which is which during the "swap" choice
                let polish = first
                let english = second
                
                // Basic deduplication if merging
                if mergeExisting && wset.words.contains(where: { $0.polish == polish && $0.english == english }) {
                    continue
                }
                
                let word = Word(polish: polish, english: english)
                word.set = wset
                wset.words.append(word)
                context.insert(word)
                importedCount += 1
            }
        }
        
        if importedCount == 0 && !mergeExisting {
            throw NSError(domain: "Verba", code: 2, userInfo: [NSLocalizedDescriptionKey: "No valid new words found in file."])
        }
        try context.save()
    }
    
    private func parseTXT(url: URL) throws -> [[String]] {
        let data = try Data(contentsOf: url)
        var parsedText: String? = nil
        
        let encodings: [String.Encoding] = [.utf8, .windowsCP1250, .isoLatin2, .isoLatin1]
        for enc in encodings {
            if let text = String(data: data, encoding: enc), !text.contains("\u{FFFD}") {
                parsedText = text
                break
            }
        }
        
        if parsedText == nil { parsedText = String(data: data, encoding: .isoLatin1) }
        guard let rawText = parsedText else {
            throw NSError(domain: "Verba", code: 1, userInfo: [NSLocalizedDescriptionKey: "Cannot determine file encoding."])
        }
        
        var rows: [[String]] = []
        let lines = rawText.components(separatedBy: .newlines)
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmedLine.isEmpty { continue }
            
            let sep: String
            if trimmedLine.contains("\t") { sep = "\t" }
            else if trimmedLine.contains("=") { sep = "=" }
            else if trimmedLine.contains(";") { sep = ";" }
            else { continue }
            
            let p = trimmedLine.components(separatedBy: sep).map{ $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            if p.count == 2, !p[0].isEmpty, !p[1].isEmpty {
                rows.append([p[0], p[1]]) 
            }
        }
        return rows
    }

    private func detectDominantLanguage(in text: String) -> (code: String, confidence: Double)? {
        let cleaned = text
            .replacingOccurrences(of: "\\d", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "[^\\p{L}\\s]", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard cleaned.count >= 12 else { return nil }
        
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(cleaned)
        let hypotheses = recognizer.languageHypotheses(withMaximum: 3)
        
        guard
            let best = hypotheses.max(by: { $0.value < $1.value }),
            best.value >= 0.35
        else {
            return nil
        }
        
        return (best.key.rawValue, best.value)
    }
    
    private func getOrCreateSet(name: String, context: ModelContext, existingSets: [WordSet], merge: Bool) -> WordSet {
        if let existing = existingSets.first(where: { $0.name == name }) {
            if !merge {
                for word in existing.words { context.delete(word) }
                existing.words.removeAll()
            }
            return existing
        } else {
            let newSet = WordSet(name: name)
            context.insert(newSet)
            return newSet
        }
    }
}
