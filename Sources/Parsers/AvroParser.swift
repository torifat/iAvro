import Foundation

final class AvroParser: @unchecked Sendable {
    static let shared = AvroParser()

    private let vowel: String
    private let consonant: String
    private let number: String
    private let caseSensitive: String
    private let patterns: [Pattern]
    private let maxPatternLength: Int

    private init() {
        let data = loadPatterns(from: "data")
        self.vowel = data.vowel
        self.consonant = data.consonant
        self.caseSensitive = data.caseSensitive
        self.number = data.number ?? ""
        self.patterns = data.patterns
        self.maxPatternLength = data.maxPatternLength
    }

    func parse(_ string: String) -> String {
        if string.isEmpty { return "" }
        return matchPatterns(
            in: string,
            vowel: vowel,
            consonant: consonant,
            number: number,
            caseSensitive: caseSensitive,
            patterns: patterns,
            maxPatternLength: maxPatternLength,
            prepareInput: { self.fix($0) },
            postProcess: { $0 }
        )
    }

    func fix(_ string: String) -> String {
        var result = ""
        for c in string.utf16 {
            if !inString(caseSensitive, c: c) {
                result += String(utf16CodeUnits: [smallCap(c)], count: 1)
            } else {
                result += String(utf16CodeUnits: [c], count: 1)
            }
        }
        return result
    }

    func isVowel(_ c: unichar) -> Bool { inString(vowel, c: c) }
    func isConsonant(_ c: unichar) -> Bool { inString(consonant, c: c) }
    func isPunctuation(_ c: unichar) -> Bool { !(isVowel(c) || isConsonant(c)) }
    func isNumber(_ c: unichar) -> Bool { inString(number, c: c) }
    func isCaseSensitive(_ c: unichar) -> Bool { inString(caseSensitive, c: c) }
}
