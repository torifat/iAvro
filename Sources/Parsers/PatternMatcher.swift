import Foundation

struct Pattern: Sendable {
    let find: String
    let replace: String
    let rules: [Rule]
}

struct Rule: Sendable {
    let matches: [Match]
    let replace: String
}

struct Match: Sendable {
    let type: String
    let scope: String
    let value: String
    let isNegative: Bool
}

func loadPatterns(from resource: String) -> (vowel: String, consonant: String, caseSensitive: String, number: String?, patterns: [Pattern], maxPatternLength: Int) {
    guard let filePath = Bundle.main.path(forResource: resource, ofType: "json"),
          let jsonData = try? Data(contentsOf: URL(fileURLWithPath: filePath)),
          let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
        fatalError("Failed to load \(resource).json")
    }

    let vowel = json["vowel"] as! String
    let consonant = json["consonant"] as! String
    let caseSensitive = json["casesensitive"] as! String
    let number = json["number"] as? String
    let rawPatterns = json["patterns"] as! [[String: Any]]

    let patterns = rawPatterns.map { dict -> Pattern in
        let find = dict["find"] as! String
        let replace = dict["replace"] as! String
        let rawRules = dict["rules"] as? [[String: Any]] ?? []
        let rules = rawRules.map { ruleDict -> Rule in
            let ruleReplace = ruleDict["replace"] as! String
            let rawMatches = ruleDict["matches"] as? [[String: Any]] ?? []
            let matches = rawMatches.map { matchDict -> Match in
                Match(
                    type: matchDict["type"] as? String ?? "",
                    scope: matchDict["scope"] as? String ?? "",
                    value: matchDict["value"] as? String ?? "",
                    isNegative: matchDict["negative"] as? Bool ?? false
                )
            }
            return Rule(matches: matches, replace: ruleReplace)
        }
        return Pattern(find: find, replace: replace, rules: rules)
    }

    let maxLen = patterns.first?.find.count ?? 0
    return (vowel, consonant, caseSensitive, number, patterns, maxLen)
}

func smallCap(_ letter: unichar) -> unichar {
    if letter >= 0x41 && letter <= 0x5A { // 'A'...'Z'
        return letter - 0x41 + 0x61 // to 'a'...'z'
    }
    return letter
}

func inString(_ str: String, c: unichar) -> Bool {
    let lc = smallCap(c)
    for scalar in str.utf16 {
        if scalar == lc { return true }
    }
    return false
}

func matchPatterns(
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
                                var chk: Int
                                if match.type == "suffix" {
                                    chk = end
                                } else {
                                    chk = start - 1
                                }

                                if match.scope == "punctuation" {
                                    let condition = (chk < 0 && match.type == "prefix") ||
                                                    (chk >= len && match.type == "suffix") ||
                                                    (chk >= 0 && chk < len && isPunctuation(fixedUTF16[chk]))
                                    if !(condition != match.isNegative) {
                                        shouldReplace = false
                                        break
                                    }
                                } else if match.scope == "vowel" {
                                    let condition = ((chk >= 0 && match.type == "prefix") ||
                                                     (chk < len && match.type == "suffix")) &&
                                                    (chk >= 0 && chk < len && isVowel(fixedUTF16[chk]))
                                    if !(condition != match.isNegative) {
                                        shouldReplace = false
                                        break
                                    }
                                } else if match.scope == "consonant" {
                                    let condition = ((chk >= 0 && match.type == "prefix") ||
                                                     (chk < len && match.type == "suffix")) &&
                                                    (chk >= 0 && chk < len && isConsonant(fixedUTF16[chk]))
                                    if !(condition != match.isNegative) {
                                        shouldReplace = false
                                        break
                                    }
                                } else if match.scope == "number" {
                                    let condition = ((chk >= 0 && match.type == "prefix") ||
                                                     (chk < len && match.type == "suffix")) &&
                                                    (chk >= 0 && chk < len && isNumber(fixedUTF16[chk]))
                                    if !(condition != match.isNegative) {
                                        shouldReplace = false
                                        break
                                    }
                                } else if match.scope == "exact" {
                                    let s: Int
                                    let e: Int
                                    if match.type == "suffix" {
                                        s = end
                                        e = end + match.value.utf16.count
                                    } else {
                                        s = start - match.value.utf16.count
                                        e = start
                                    }
                                    if !isExact(match.value, haystack: fixedUTF16, start: s, end: e, not: match.isNegative) {
                                        shouldReplace = false
                                        break
                                    }
                                }
                            }

                            if shouldReplace {
                                output += postProcess(rule.replace)
                                cur = end - 1
                                matched = true
                                break
                            }
                        }

                        if !matched {
                            // Default replacement
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
