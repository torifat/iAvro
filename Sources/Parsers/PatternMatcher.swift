import Foundation

// MARK: - Enums

enum MatchType: String, Sendable, Codable {
    case prefix
    case suffix
}

enum MatchScope: String, Sendable, Codable {
    case punctuation
    case vowel
    case consonant
    case number
    case exact
}

// MARK: - Decodable Models

struct Pattern: Sendable, Decodable {
    let find: String
    let replace: String
    let rules: [Rule]
}

struct Rule: Sendable, Decodable {
    let matches: [Match]
    let replace: String
}

struct Match: Sendable, Decodable {
    let type: MatchType
    let scope: MatchScope
    let value: String
    let isNegative: Bool

    private enum CodingKeys: String, CodingKey {
        case type, scope, value, negative
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(MatchType.self, forKey: .type)
        scope = try container.decode(MatchScope.self, forKey: .scope)
        value = try container.decodeIfPresent(String.self, forKey: .value) ?? ""
        // JSON uses "YES"/"NO"/"TRUE"/"FALSE" strings, not JSON booleans
        let negativeStr = try container.decodeIfPresent(String.self, forKey: .negative) ?? "NO"
        isNegative = negativeStr.uppercased() == "YES" || negativeStr.uppercased() == "TRUE"
    }
}

private struct PatternData: Sendable, Decodable {
    let vowel: String
    let consonant: String
    let caseSensitive: String
    let number: String?
    let patterns: [Pattern]

    private enum CodingKeys: String, CodingKey {
        case vowel, consonant, patterns, number
        case caseSensitive = "casesensitive"
    }
}

// MARK: - PatternMatcher

enum PatternMatcher {

    struct LoadResult: Sendable {
        let vowel: String
        let consonant: String
        let caseSensitive: String
        let number: String?
        let patterns: [Pattern]
        let maxPatternLength: Int
    }

    static func load(from resource: String) -> LoadResult {
        guard let url = Bundle.main.url(forResource: resource, withExtension: "json"),
              let jsonData = try? Data(contentsOf: url) else {
            fatalError("Failed to load \(resource).json from bundle")
        }

        let data: PatternData
        do {
            data = try JSONDecoder().decode(PatternData.self, from: jsonData)
        } catch {
            fatalError("Failed to decode \(resource).json: \(error)")
        }

        let maxLen = data.patterns.first?.find.count ?? 0
        return LoadResult(
            vowel: data.vowel,
            consonant: data.consonant,
            caseSensitive: data.caseSensitive,
            number: data.number,
            patterns: data.patterns,
            maxPatternLength: maxLen
        )
    }

    // MARK: - Character Classification Helpers

    static func smallCap(_ letter: unichar) -> unichar {
        if letter >= 0x41 && letter <= 0x5A { // 'A'...'Z'
            return letter - 0x41 + 0x61       // to 'a'...'z'
        }
        return letter
    }

    static func inString(_ str: String, c: unichar) -> Bool {
        let lc = smallCap(c)
        for scalar in str.utf16 {
            if scalar == lc { return true }
        }
        return false
    }

    // MARK: - Pattern Matching Engine

    static func match(
        in string: String,
        vowel: String,
        consonant: String,
        number: String?,
        caseSensitive: String,
        patterns: [Pattern],
        maxPatternLength: Int,
        prepareInput: (String) -> String,
        postProcess: (String) -> String
    ) -> String {
        if string.isEmpty { return string }

        let fixed = prepareInput(string)
        var output = ""
        let fixedUTF16 = Array(fixed.utf16)
        let len = fixedUTF16.count

        func isVowel(_ c: unichar) -> Bool { inString(vowel, c: c) }
        func isConsonant(_ c: unichar) -> Bool { inString(consonant, c: c) }
        func isNumber(_ c: unichar) -> Bool {
            guard let num = number else { return false }
            return inString(num, c: c)
        }
        func isPunctuation(_ c: unichar) -> Bool { !(isVowel(c) || isConsonant(c)) }

        func isExact(_ needle: String, haystack: [unichar], start: Int, end: Int, not: Bool) -> Bool {
            let needleLen = end - start
            guard start >= 0, end <= haystack.count, needleLen == needle.utf16.count else {
                return not
            }
            let slice = Array(haystack[start..<end])
            let needleUTF16 = Array(needle.utf16)
            return (slice == needleUTF16) != not
        }

        var cur = 0
        while cur < len {
            let start = cur
            var matched = false

            var chunkLen = maxPatternLength
            while chunkLen > 0 && !matched {
                let end = start + chunkLen
                if end <= len {
                    let chunkUTF16 = Array(fixedUTF16[start..<end])
                    let chunk = String(utf16CodeUnits: chunkUTF16, count: chunkUTF16.count)

                    // Binary Search
                    var left = 0
                    var right = patterns.count - 1
                    while right >= left {
                        let mid = (right + left) / 2
                        let pattern = patterns[mid]
                        let find = pattern.find
                        if find == chunk {
                            for rule in pattern.rules {
                                var shouldReplace = true
                                for match in rule.matches {
                                    let chk: Int
                                    switch match.type {
                                    case .suffix: chk = end
                                    case .prefix: chk = start - 1
                                    }

                                    switch match.scope {
                                    case .punctuation:
                                        let condition = (chk < 0 && match.type == .prefix) ||
                                                        (chk >= len && match.type == .suffix) ||
                                                        (chk >= 0 && chk < len && isPunctuation(fixedUTF16[chk]))
                                        if !(condition != match.isNegative) {
                                            shouldReplace = false
                                        }

                                    case .vowel:
                                        let condition = ((chk >= 0 && match.type == .prefix) ||
                                                         (chk < len && match.type == .suffix)) &&
                                                        (chk >= 0 && chk < len && isVowel(fixedUTF16[chk]))
                                        if !(condition != match.isNegative) {
                                            shouldReplace = false
                                        }

                                    case .consonant:
                                        let condition = ((chk >= 0 && match.type == .prefix) ||
                                                         (chk < len && match.type == .suffix)) &&
                                                        (chk >= 0 && chk < len && isConsonant(fixedUTF16[chk]))
                                        if !(condition != match.isNegative) {
                                            shouldReplace = false
                                        }

                                    case .number:
                                        let condition = ((chk >= 0 && match.type == .prefix) ||
                                                         (chk < len && match.type == .suffix)) &&
                                                        (chk >= 0 && chk < len && isNumber(fixedUTF16[chk]))
                                        if !(condition != match.isNegative) {
                                            shouldReplace = false
                                        }

                                    case .exact:
                                        let s: Int
                                        let e: Int
                                        if match.type == .suffix {
                                            s = end
                                            e = end + match.value.utf16.count
                                        } else {
                                            s = start - match.value.utf16.count
                                            e = start
                                        }
                                        if !isExact(match.value, haystack: fixedUTF16, start: s, end: e, not: match.isNegative) {
                                            shouldReplace = false
                                        }
                                    }

                                    if !shouldReplace { break }
                                }

                                if shouldReplace {
                                    output += postProcess(rule.replace)
                                    cur = end - 1
                                    matched = true
                                    break
                                }
                            }

                            if !matched {
                                output += postProcess(pattern.replace)
                                cur = end - 1
                                matched = true
                            }
                            break
                        } else if find.utf16.count > chunkUTF16.count ||
                                  (find.utf16.count == chunkUTF16.count && find < chunk) {
                            left = mid + 1
                        } else {
                            right = mid - 1
                        }
                    }
                }
                chunkLen -= 1
            }

            if !matched {
                let c = fixedUTF16[cur]
                output += String(utf16CodeUnits: [c], count: 1)
            }
            cur += 1
        }

        return output
    }
}
