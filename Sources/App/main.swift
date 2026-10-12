import Cocoa
@preconcurrency import InputMethodKit

MainActor.assumeIsolated {
    // Initialize parsers
    _ = AvroParser.shared
    _ = SuggestionEngine.shared

    // Initialize preferences
    IMPreferences.initializeDefaults()
    let imPref = IMPreferences()

    // Initialize IMK server
    let connectionName = "Avro_Keyboard_Connection"
    guard let bundleIdentifier = Bundle.main.bundleIdentifier else {
        fatalError("No bundle identifier")
    }
    guard let server = IMKServer(name: connectionName, bundleIdentifier: bundleIdentifier) else {
        fatalError("Failed to create IMKServer")
    }

    // Initialize candidates panel
    CandidatesPanel.initialize(with: server)

    // Load MainMenu NIB
    Bundle.main.loadNibNamed("MainMenu", owner: NSApplication.shared, topLevelObjects: nil)

    // Set preferences on delegate
    if let delegate = NSApp.delegate as? AppDelegate {
        delegate.imPref = imPref
    }

    // Run the application
    NSApplication.shared.run()
}
