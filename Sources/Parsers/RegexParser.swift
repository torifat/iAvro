import Foundation

final class RegexParser: @unchecked Sendable {
    static let shared = RegexParser()

    private let vowel: String
    private let consonant: String
    private let caseSensitive: String
    private let patterns: [Pattern]
    private let maxPatternLength: Int

    private static let banglaRegexSuffix = "(\u{09CD}[\u{09AF}\u{09AC}\u{09AE}])?(\u{09CD}?)([\u{09C3}\u{0981}]?)"

    private init() {
        let data = PatternMatcher.load(from: "regex")
        self.vowel = data.vowel
        self.consonant = data.consonant
        self.caseSensitive = data.caseSensitive
        self.patterns = data.patterns
        self.maxPatternLength = data.maxPatternLength
    }

    func parse(_ string: String) -> String {
        if string.isEmpty { return string }
        return PatternMatcher.match(
            in: string,
            vowel: vowel,
            consonant: consonant,
            number: nil,
            caseSensitive: caseSensitive,
            patterns: patterns,
            maxPatternLength: maxPatternLength,
            prepareInput: { self.clean($0) },
            postProcess: { $0 + Self.banglaRegexSuffix }
        )
    }

    private func clean(_ string: String) -> String {
        var result = ""
        for c in string.utf16 {
            if !PatternMatcher.inString(caseSensitive, c: c) {
                result += String(utf16CodeUnits: [PatternMatcher.smallCap(c)], count: 1)
            }
        }
        return result
    }
}
