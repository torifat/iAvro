import XCTest
@testable import Avro_Keyboard

/// Tests for Database regex caching.
final class DatabaseTests: XCTestCase {

    func testRegexCacheHit() {
        // Calling find twice with the same term should use the cached regex
        // We can't directly test the cache, but we can verify consistency
        let result1 = Database.shared.find(term: "test")
        let result2 = Database.shared.find(term: "test")
        XCTAssertEqual(Set(result1), Set(result2))
    }

    func testRegexCacheDoesNotReturnStaleResults() {
        // Different terms should produce different regexes
        let resultA = Database.shared.find(term: "ami")
        let resultB = Database.shared.find(term: "tumi")
        // Results may or may not overlap, but they should be independent
        // The key thing is that it doesn't crash and returns consistent results
        XCTAssertEqual(Set(resultA), Set(Database.shared.find(term: "ami")))
        XCTAssertEqual(Set(resultB), Set(Database.shared.find(term: "tumi")))
    }

    func testEmptyTermReturnsEmpty() {
        let result = Database.shared.find(term: "")
        XCTAssertTrue(result.isEmpty)
    }
}
