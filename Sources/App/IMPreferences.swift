import AppKit
import SwiftUI

@MainActor
@objc final class IMPreferences: NSObject {
    private var preferencesWindow: NSWindow?

    @objc static func initializeDefaults() {
        guard let url = Bundle.main.url(forResource: "preferences", withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let prefDict = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any] else {
            return
        }
        UserDefaults.standard.register(defaults: prefDict)
    }

    @objc func showPreferencesWindow() {
        if let existing = preferencesWindow, existing.isVisible {
            existing.makeKeyAndOrderFront(nil)
            return
        }

        let hostingView = NSHostingView(rootView: PreferencesView())
        hostingView.frame = NSRect(x: 0, y: 0, width: 450, height: 250)

        let window = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 450, height: 250),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Preferences"
        window.contentView = hostingView
        window.center()
        window.isReleasedWhenClosed = false
        window.hidesOnDeactivate = false
        window.level = .modalPanel

        preferencesWindow = window
        window.makeKeyAndOrderFront(nil)
    }
}
