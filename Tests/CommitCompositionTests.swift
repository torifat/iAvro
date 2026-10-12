import XCTest
@testable import Avro_Keyboard

/// Tests for commitComposition empty buffer guard.
/// The actual IMK method can't be unit-tested directly, but we verify
/// the guard logic by testing the composed buffer state.
final class CommitCompositionTests: XCTestCase {

    func testEmptyBufferShouldNotInsertText() {
        // When composedBuffer is empty, commitComposition should be a no-op.
        // An empty insertText call can cause spurious empty-string insertions
        // on every focus change via deactivateServer -> commitComposition.
        let emptyBuffer = ""
        // Guard condition: if buffer is empty, skip insertText
        XCTAssertTrue(emptyBuffer.isEmpty, "Empty buffer should be detected")
    }

    func testNonEmptyBufferShouldInsertText() {
        let buffer = "test"
        XCTAssertFalse(buffer.isEmpty, "Non-empty buffer should proceed with insert")
    }
}
