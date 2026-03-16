import Cocoa

@objc(MainMenuAppDelegate)
@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    // Outlet name must match NIB key "_menu" (from original ObjC ivar)
    @IBOutlet @objc var _menu: NSMenu!

    @objc var imPref: IMPreferences?

    var menu: NSMenu! { _menu }

    override func awakeFromNib() {
        super.awakeFromNib()

        if let prefsItem = _menu?.item(withTag: 1) {
            prefsItem.action = #selector(AvroKeyboardController.showPreferences(_:))
        }

        if UserDefaults.standard.bool(for: .includeDictionary) {
            NSLog("Loading Dictionary...")
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
