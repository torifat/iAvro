import XCTest
@testable import Avro_Keyboard

/// Tests that AvroParser.fix() and RegexParser produce the same output after refactoring.
final class ParserStringBuildingTests: XCTestCase {

    func testFixLowercasesNonCaseSensitiveChars() {
        let parser = AvroParser.shared
        // 'o','i','u','d','g','j','n','r','s','t','y','z' are case-sensitive
        // Other ASCII letters should be lowercased; O is case-sensitive → preserved as-is
        XCTAssertEqual(parser.fix("HELLO"), "hellO")  // uppercase O stays
        XCTAssertEqual(parser.fix("Hello"), "hello")   // lowercase o stays
        // All non-case-sensitive: ABCEFHKLMPQVWX → abcefhklmpqvwx
        XCTAssertEqual(parser.fix("ABC"), "abc")
    }

    func testFixPreservesCaseSensitiveChars() {
        let parser = AvroParser.shared
        // Capital O, I, U, D, G, J, N, R, S, T, Y, Z should be preserved
        XCTAssertEqual(parser.fix("OI"), "OI")
        XCTAssertEqual(parser.fix("NG"), "NG")
        XCTAssertEqual(parser.fix("Sh"), "Sh")
        XCTAssertEqual(parser.fix("Th"), "Th")
    }

    func testFixMixedInput() {
        let parser = AvroParser.shared
        // "Bangladesh" → 'B' not case-sensitive → 'b', 'a' not → 'a',
        // 'n' is case-sensitive → stays 'n', etc.
        let result = parser.fix("Bangladesh")
        // All non-case-sensitive uppercase → lower, case-sensitive stays as-is
        XCTAssertFalse(result.isEmpty)
        // First character 'B' is not case-sensitive, should become 'b'
        XCTAssertTrue(result.hasPrefix("b"))
    }

    func testFixEmptyString() {
        XCTAssertEqual(AvroParser.shared.fix(""), "")
    }

    func testParseProducesOutput() {
        // Basic sanity: parsing "ami" should produce Bengali output
        let result = AvroParser.shared.parse("ami")
        XCTAssertFalse(result.isEmpty)
        // "ami" should produce "আমি"
        XCTAssertEqual(result, "আমি")
    }

    func testRegexParseProducesOutput() {
        // RegexParser should produce a regex pattern
        let result = RegexParser.shared.parse("ami")
        XCTAssertFalse(result.isEmpty)
    }
}
