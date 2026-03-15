import XCTest
@testable import Avro_Keyboard

/// Tests for PatternMatcher JSON loading safety.
final class PatternMatcherTests: XCTestCase {

    func testLoadPatternsFromDataJson() {
        // Should load without crashing (validates all guard lets pass)
        let result = loadPatterns(from: "data")
        XCTAssertFalse(result.vowel.isEmpty)
        XCTAssertFalse(result.consonant.isEmpty)
        XCTAssertFalse(result.caseSensitive.isEmpty)
        XCTAssertFalse(result.patterns.isEmpty)
        XCTAssertGreaterThan(result.maxPatternLength, 0)
    }

    func testPatternsHaveValidFindAndReplace() {
        let result = loadPatterns(from: "data")
        for pattern in result.patterns {
            XCTAssertFalse(pattern.find.isEmpty, "Pattern find should not be empty")
            // replace can be empty (some patterns intentionally produce empty output)
        }
    }

    func testRulesHaveReplaceField() {
        let result = loadPatterns(from: "data")
        let patternsWithRules = result.patterns.filter { !$0.rules.isEmpty }
        XCTAssertFalse(patternsWithRules.isEmpty, "Should have patterns with rules")
        for pattern in patternsWithRules {
            for rule in pattern.rules {
                // rule.replace exists (was loaded successfully via guard let)
                _ = rule.replace
            }
        }
    }
}
