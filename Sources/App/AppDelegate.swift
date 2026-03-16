import Cocoa
import os

@objc(MainMenuAppDelegate)
@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    private static let log = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.omicronlab.avro", category: "AppDelegate")
    @IBOutlet @objc var menu: NSMenu!

    @objc var imPref: IMPreferences?

    override func awakeFromNib() {
        super.awakeFromNib()

        if let prefsItem = menu?.item(withTag: 1) {
            prefsItem.action = #selector(AvroKeyboardController.showPreferences(_:))
        }

        if UserDefaults.standard.bool(for: .includeDictionary) {
            Self.log.info("Loading Dictionary...")
            _ = Database.shared
            _ = RegexParser.shared
            _ = CacheManager.shared
        }
        _ = AutoCorrect.shared
    }

    func applicationWillTerminate(_ notification: Notification) {
        if UserDefaults.standard.bool(for: .includeDictionary) {
            CacheManager.shared.persist()
        }
    }
}
