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

        let tabVC = NSTabViewController()
        tabVC.tabStyle = .toolbar

        // General
        let generalVC = NSHostingController(rootView: GeneralTab())
        generalVC.sizingOptions = .preferredContentSize
        let generalItem = NSTabViewItem(viewController: generalVC)
        generalItem.label = "General"
        generalItem.image = NSImage(systemSymbolName: "gearshape", accessibilityDescription: "General")
        tabVC.addTabViewItem(generalItem)

        // AutoCorrect
        let autoCorrectVC = NSHostingController(rootView: AutoCorrectTab())
        autoCorrectVC.preferredContentSize = NSSize(width: 450, height: 340)
        let autoCorrectItem = NSTabViewItem(viewController: autoCorrectVC)
        autoCorrectItem.label = "AutoCorrect"
        autoCorrectItem.image = NSImage(systemSymbolName: "text.badge.checkmark", accessibilityDescription: "AutoCorrect")
        tabVC.addTabViewItem(autoCorrectItem)

        // Credits
        let creditsVC = NSHostingController(rootView: CreditsTab())
        creditsVC.preferredContentSize = NSSize(width: 450, height: 300)
        let creditsItem = NSTabViewItem(viewController: creditsVC)
        creditsItem.label = "Credits"
        creditsItem.image = NSImage(systemSymbolName: "info.circle", accessibilityDescription: "Credits")
        tabVC.addTabViewItem(creditsItem)

        let window = NSWindow(contentViewController: tabVC)
        window.title = "Preferences"
        window.styleMask = [.titled, .closable]
        window.center()
        window.isReleasedWhenClosed = false
        window.level = .floating

        preferencesWindow = window
        window.makeKeyAndOrderFront(nil)
    }
}
