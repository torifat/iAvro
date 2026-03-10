import AppKit

@MainActor
@objc final class IMPreferences: NSObject {
    private var windowController: NSWindowController?

    @objc static func initializeDefaults() {
        guard let prefFile = Bundle.main.path(forResource: "preferences", ofType: "plist"),
              let prefDict = NSDictionary(contentsOfFile: prefFile) as? [String: Any] else {
            return
        }
        UserDefaults.standard.register(defaults: prefDict)
        NSUserDefaultsController.shared.initialValues = prefDict
    }

    @objc func getWindowController() -> NSWindowController {
        if windowController == nil {
            windowController = NSWindowController(windowNibName: "preferences")
        }
        return windowController!
    }
}
