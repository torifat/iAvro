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

    func testScalarVsCharacterCountMismatch() {
        // "ক্ষ" is 1 Character (grapheme cluster) but 3 unicode scalars (ক + ্ + ষ)
        let conjunct = "ক্ষ"
        XCTAssertEqual(conjunct.count, 1, "Should be 1 grapheme cluster")
        XCTAssertEqual(conjunct.unicodeScalars.count, 3, "Should be 3 unicode scalars")

        // Distance between "ক্ষ" and "কষ" should be 1 (delete the virama ্)
        // If we used .count (1) for DP dimensions, we'd only compare the first scalar
        let distance = conjunct.levenshteinDistance(to: "কষ")
        XCTAssertEqual(distance, 1, "Should count virama as a deletable scalar")
    }

    func testCombiningCharacterDistance() {
        // "é" (U+00E9): 1 scalar. "e\u{0301}" (e + combining accent): 2 scalars.
        // Both are 1 Character visually, but scalar counts differ.
        // Distance = 2: substitute U+00E9→U+0065 + insert U+0301
        let composed = "é"
        let decomposed = "\u{0065}\u{0301}"
        let distance = composed.levenshteinDistance(to: decomposed)
        XCTAssertEqual(distance, 2, "Composed vs decomposed: substitute + insert = 2")
    }
}
