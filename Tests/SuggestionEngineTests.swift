import XCTest
@testable import Avro_Keyboard

/// Tests for SuggestionEngine edge cases.
@MainActor
final class SuggestionEngineTests: XCTestCase {

    func testSuffixPrefixExtractionSafety() {
        // String(suffix.prefix(1)) is safe on empty strings
        let empty = ""
        let result = String(empty.prefix(1))
        XCTAssertEqual(result, "")
    }

    func testSuffixPrefixExtractionOnSingleChar() {
        let single = "\u{09BE}" // Bengali aa-kar
        let result = String(single.prefix(1))
        XCTAssertEqual(result, "\u{09BE}")
    }

    func testSuffixPrefixExtractionOnMultiChar() {
        let multi = "\u{09BE}\u{09B0}" // aa-kar + ra
        let result = String(multi.prefix(1))
        XCTAssertEqual(result, "\u{09BE}")
    }

    func testGetListWithEmptyTermReturnsEmpty() {
        // Empty term should return empty list, not crash
        let result = SuggestionEngine.shared.getList("")
        XCTAssertTrue(result.isEmpty)
    }
}
