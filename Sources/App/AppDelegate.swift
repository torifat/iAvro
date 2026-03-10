import Cocoa

@objc(MainMenuAppDelegate)
@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    @IBOutlet var menu: NSMenu!

    @objc var imPref: IMPreferences?

    override func awakeFromNib() {
        super.awakeFromNib()

        if let prefsItem = menu.item(withTag: 1) {
            prefsItem.action = #selector(AvroKeyboardController.showPreferences(_:))
        }

        if UserDefaults.standard.bool(forKey: "IncludeDictionary") {
            NSLog("Loading Dictionary...")
            _ = Database.shared
            _ = RegexParser.shared
            _ = CacheManager.shared
        }
        _ = AutoCorrect.shared
    }

    func applicationWillTerminate(_ notification: Notification) {
        if UserDefaults.standard.bool(forKey: "IncludeDictionary") {
            CacheManager.shared.persist()
        }
    }
}
