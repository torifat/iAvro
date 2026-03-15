import XCTest

/// Tests that verify the UTF-16 vs Character count distinction
/// for Bengali strings used in NSRange calculations.
final class UTF16RangeTests: XCTestCase {

    func testBengaliCharacterVsUTF16Count() {
        // Bengali conjuncts can differ between .count and .utf16.count
        // Example: "ক্ষ" (ksha) is 1 Character but 3 UTF-16 code units
        let ksha = "\u{0995}\u{09CD}\u{09B7}" // ক্ষ
        XCTAssertEqual(ksha.count, 1)
        XCTAssertEqual(ksha.utf16.count, 3)
    }

    func testBengaliWithKarUTF16Mismatch() {
        // "কি" (ki) — ক + ি  = 1 Character, 2 UTF-16 code units
        let ki = "\u{0995}\u{09BF}" // কি
        XCTAssertEqual(ki.count, 1)
        XCTAssertEqual(ki.utf16.count, 2)
    }

    func testNSStringLengthMatchesUTF16Count() {
        let bangla = "বাংলা"
        XCTAssertEqual((bangla as NSString).length, bangla.utf16.count)
        // .count may differ from .utf16.count for Bengali text
        // This is why NSRange must use utf16.count, not .count
    }

    func testNSRangeWithUTF16ForMarkedText() {
        // Simulates the NSRange used for setMarkedText cursor position
        let buffer = "\u{0995}\u{09CD}\u{09B7}" // ক্ষ — 1 char, 3 utf16
        let correctRange = NSRange(location: buffer.utf16.count, length: 0)
        let wrongRange = NSRange(location: buffer.count, length: 0)

        XCTAssertEqual(correctRange.location, 3)
        XCTAssertEqual(wrongRange.location, 1) // Would misplace the cursor
        XCTAssertNotEqual(correctRange, wrongRange)
    }

    func testPrefixSuffixUTF16LengthForSubstring() {
        // Simulates candidateSelectionChanged NSRange calculation
        let prefix = "বাং"  // prefix
        let suffix = "লা"   // suffix
        let full = "বাংটেস্টলা"

        let nsPrefix = (prefix as NSString).length
        let nsSuffix = (suffix as NSString).length
        let nsFull = (full as NSString).length

        // The middle portion range should use NSString lengths
        let range = NSRange(location: nsPrefix, length: nsFull - nsPrefix - nsSuffix)
        let extracted = (full as NSString).substring(with: range)

        // Verify the extraction works correctly with UTF-16 lengths
        XCTAssertFalse(extracted.isEmpty)
    }
}
