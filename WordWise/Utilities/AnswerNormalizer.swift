import Foundation

protocol AnswerNormalizing {
    func normalize(_ text: String) -> String
    func variants(for target: String) -> Set<String>
}

struct AnswerNormalizer: AnswerNormalizing {
    private let separators = CharacterSet(charactersIn: ",/-;")

    func normalize(_ text: String) -> String {
        let collapsed = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: "\u{2019}", with: "'")
            .replacingOccurrences(of: "\u{00A0}", with: " ")
            .replacingOccurrences(of: "\u{200B}", with: "")
            .replacingOccurrences(of: "\u{FEFF}", with: "")
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        return transliterateToASCII(collapsed)
    }

    func variants(for target: String) -> Set<String> {
        var values = Set(
            target
                .components(separatedBy: separators)
                .map(normalize)
                .filter { !$0.isEmpty }
        )

        let normalizedWhole = normalize(target)
        if !normalizedWhole.isEmpty {
            values.insert(normalizedWhole)
        }

        return values
    }

    private func transliterateToASCII(_ text: String) -> String {
        guard
            let latin = text.applyingTransform(.toLatin, reverse: false),
            let stripped = latin.applyingTransform(.stripCombiningMarks, reverse: false)
        else {
            return text.folding(options: .diacriticInsensitive, locale: .current)
        }

        return stripped
            .replacingOccurrences(of: "ł", with: "l")
            .replacingOccurrences(of: "Ł", with: "L")
    }
}
