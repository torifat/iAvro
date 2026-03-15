import XCTest
@testable import Avro_Keyboard

@MainActor
final class CacheManagerTests: XCTestCase {

    func testPhoneticCacheEvictsOldestEntries() {
        let cache = CacheManager.shared

        // Fill cache beyond the cap (512 entries)
        for i in 0..<600 {
            cache.setArray(["value\(i)"], forKey: "key\(i)")
        }

        // Recent entries should still exist
        XCTAssertNotNil(cache.array(forKey: "key599"))
        XCTAssertNotNil(cache.array(forKey: "key550"))

        // Oldest entries should have been evicted
        XCTAssertNil(cache.array(forKey: "key0"))
        XCTAssertNil(cache.array(forKey: "key50"))
    }

    func testPhoneticCacheAccessRefreshesEntry() {
        let cache = CacheManager.shared

        // Reset by filling with known keys
        for i in 0..<500 {
            cache.setArray(["val\(i)"], forKey: "lru\(i)")
        }

        // Access an early key to refresh it
        _ = cache.array(forKey: "lru0")

        // Now add enough to trigger eviction
        for i in 500..<600 {
            cache.setArray(["val\(i)"], forKey: "lru\(i)")
        }

        // lru0 was accessed recently, should survive eviction
        XCTAssertNotNil(cache.array(forKey: "lru0"))
    }
}
