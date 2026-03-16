import AppKit

@MainActor
@objc final class IMPreferences: NSObject {
    private var windowController: NSWindowController?

    @objc static func initializeDefaults() {
        guard let url = Bundle.main.url(forResource: "preferences", withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let prefDict = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any] else {
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
