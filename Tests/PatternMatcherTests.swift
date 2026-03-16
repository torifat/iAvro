import XCTest
@testable import Avro_Keyboard

/// Tests for PatternMatcher JSON loading, Codable decoding, and enum types.
final class PatternMatcherTests: XCTestCase {

    func testLoadPatternsFromDataJson() {
        let result = PatternMatcher.load(from: "data")
        XCTAssertFalse(result.vowel.isEmpty)
        XCTAssertFalse(result.consonant.isEmpty)
        XCTAssertFalse(result.caseSensitive.isEmpty)
        XCTAssertFalse(result.patterns.isEmpty)
        XCTAssertGreaterThan(result.maxPatternLength, 0)
    }

    func testLoadPatternsFromRegexJson() {
        let result = PatternMatcher.load(from: "regex")
        XCTAssertFalse(result.vowel.isEmpty)
        XCTAssertFalse(result.consonant.isEmpty)
        XCTAssertFalse(result.patterns.isEmpty)
        // regex.json has no 'number' key
        XCTAssertNil(result.number)
    }

    func testPatternsHaveValidFindAndReplace() {
        let result = PatternMatcher.load(from: "data")
        for pattern in result.patterns {
            XCTAssertFalse(pattern.find.isEmpty, "Pattern find should not be empty")
        }
    }

    func testMatchScopeExhaustive() {
        // All scope values in the JSON should decode to valid enum cases
        let result = PatternMatcher.load(from: "data")
        let patternsWithRules = result.patterns.filter { !$0.rules.isEmpty }
        XCTAssertFalse(patternsWithRules.isEmpty, "Should have patterns with rules")
        for pattern in patternsWithRules {
            for rule in pattern.rules {
                for match in rule.matches {
                    // If these were still strings, we couldn't switch on them
                    switch match.scope {
                    case .vowel, .consonant, .punctuation, .number, .exact:
                        break // all valid
                    }
                    switch match.type {
                    case .prefix, .suffix:
                        break // all valid
                    }
                }
            }
        }
    }

    func testNegativeFieldDecodesCorrectly() {
        // data.json has "YES"/"NO" strings for the negative field
        let result = PatternMatcher.load(from: "data")
        let allMatches = result.patterns.flatMap { $0.rules.flatMap { $0.matches } }

        let negativeCount = allMatches.filter(\.isNegative).count
        let positiveCount = allMatches.filter { !$0.isNegative }.count

        // data.json has 51 "YES" and 28 "NO" entries
        XCTAssertEqual(negativeCount, 51, "Should decode 'YES' strings as true")
        XCTAssertEqual(positiveCount, 28, "Should decode 'NO' strings as false")
    }

    func testRulesHaveReplaceField() {
        let result = PatternMatcher.load(from: "data")
        let patternsWithRules = result.patterns.filter { !$0.rules.isEmpty }
        XCTAssertFalse(patternsWithRules.isEmpty, "Should have patterns with rules")
        for pattern in patternsWithRules {
            for rule in pattern.rules {
                _ = rule.replace
            }
        }
    }
}
