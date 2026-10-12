import XCTest
@testable import Avro_Keyboard

/// Tests that centralized UserDefaults keys match expected raw values.
final class UserDefaultsKeyTests: XCTestCase {

    func testKeyRawValues() {
        // Ensure the enum raw values match the strings used in preferences.plist and NIB bindings
        XCTAssertEqual(UserDefaults.Key.includeDictionary.rawValue, "IncludeDictionary")
        XCTAssertEqual(UserDefaults.Key.candidatePanelType.rawValue, "CandidatePanelType")
        XCTAssertEqual(UserDefaults.Key.commitNewLineOnEnter.rawValue, "CommitNewLineOnEnter")
    }

    func testTypedAccessors() {
        let defaults = UserDefaults.standard
        // bool(for:) should return same value as bool(forKey:)
        XCTAssertEqual(defaults.bool(for: .includeDictionary),
                       defaults.bool(forKey: "IncludeDictionary"))
        XCTAssertEqual(defaults.integer(for: .candidatePanelType),
                       defaults.integer(forKey: "CandidatePanelType"))
    }
}
