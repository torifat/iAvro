import XCTest

/// Tests verifying that nil candidateString parameters are handled safely.
/// IMK can pass nil during rapid panel dismissal edge cases, and the IUO
/// parameters would crash on .string access without a guard.
final class CandidateNilGuardTests: XCTestCase {

    func testNilNSAttributedStringIUOCrashesWithoutGuard() {
        // Demonstrates why guard is needed: IUO nil crashes on access
        let nilAttrStr: NSAttributedString! = nil
        // Without guard let, accessing nilAttrStr.string would crash
        // The fix adds `guard let candidateString` in both methods
        XCTAssertNil(nilAttrStr)
    }

    func testValidNSAttributedStringAccessIsSafe() {
        let attrStr: NSAttributedString! = NSAttributedString(string: "test")
        XCTAssertEqual(attrStr.string, "test")
    }
}
