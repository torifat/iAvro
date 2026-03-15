import XCTest
@testable import Avro_Keyboard

final class LevenshteinTests: XCTestCase {

    func testBothEmpty() {
        XCTAssertEqual("".levenshteinDistance(to: ""), 0)
    }

    func testFirstEmpty() {
        XCTAssertEqual("".levenshteinDistance(to: "abc"), 3)
    }

    func testSecondEmpty() {
        XCTAssertEqual("abc".levenshteinDistance(to: ""), 3)
    }

    func testIdentical() {
        XCTAssertEqual("hello".levenshteinDistance(to: "hello"), 0)
    }

    func testSingleInsertion() {
        XCTAssertEqual("abc".levenshteinDistance(to: "abcd"), 1)
    }

    func testSingleDeletion() {
        XCTAssertEqual("abcd".levenshteinDistance(to: "abc"), 1)
    }

    func testSingleSubstitution() {
        XCTAssertEqual("abc".levenshteinDistance(to: "axc"), 1)
    }

    func testBengaliStrings() {
        // Same string
        XCTAssertEqual("বাংলা".levenshteinDistance(to: "বাংলা"), 0)
        // Different Bengali strings
        XCTAssertGreaterThan("অভ্র".levenshteinDistance(to: "বাংলা"), 0)
    }

    func testEmptyStringsSortingCorrectness() {
        // Ensure empty string distance doesn't corrupt sort order
        // -1 would sort before 0, breaking Levenshtein-based sorting
        let dist = "".levenshteinDistance(to: "test")
        XCTAssertGreaterThanOrEqual(dist, 0, "Levenshtein distance must never be negative")
    }
}
