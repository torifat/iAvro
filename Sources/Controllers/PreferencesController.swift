import AppKit

@objc(PreferencesController)
@MainActor
class PreferencesController: NSWindowController {
    @IBOutlet private var aboutView: NSView!
    @IBOutlet private var autoCorrectView: NSView!
    @IBOutlet private var generalView: NSView!
    @IBOutlet private var aboutContent: NSTextView!
    @IBOutlet private var autoCorrectController: NSArrayController!

    @objc dynamic var autoCorrectItemsArray: [AutoCorrectItem] = []
    private var currentViewTag: Int = 0

    override init(window: NSWindow?) {
        super.init(window: window)
        loadAutoCorrectItems()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        loadAutoCorrectItems()
    }

    private func loadAutoCorrectItems() {
        let entries = AutoCorrect.shared.entries
        autoCorrectItemsArray = entries.map { key, value in
            AutoCorrectItem(replace: key, with: value)
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        window?.setContentSize(generalView.frame.size)
        window?.contentView?.addSubview(generalView)
        window?.contentView?.wantsLayer = true

        if let creditsPath = Bundle.main.path(forResource: "Credits", ofType: "rtfd") {
            aboutContent.readRTFD(fromFile: creditsPath)
            aboutContent.scrollToBeginningOfDocument(aboutContent)
        }
    }

    private func newFrame(for view: NSView) -> NSRect {
        guard let window = self.window else { return .zero }
        let newFrameRect = window.frameRect(forContentRect: view.frame)
        let oldFrameRect = window.frame
        var frame = window.frame
        frame.size = newFrameRect.size
        frame.origin.y -= (newFrameRect.size.height - oldFrameRect.size.height)
        return frame
    }

    private func view(forTag tag: Int) -> NSView {
        switch tag {
        case 0: return generalView
        case 1: return autoCorrectView
        default: return aboutView
        }
    }

    @objc func validateToolbarItem(_ item: NSToolbarItem) -> Bool {
        return item.tag != currentViewTag
    }

    @IBAction func switchView(_ sender: NSToolbarItem) {
        let tag = sender.tag
        let newView = view(forTag: tag)
        let previousView = view(forTag: currentViewTag)
        currentViewTag = tag
        let newFrame = self.newFrame(for: newView)

        NSAnimationContext.beginGrouping()

        if NSApp.currentEvent?.modifierFlags.contains(.shift) == true {
            NSAnimationContext.current.duration = 1.0
        }

        window?.contentView?.animator().replaceSubview(previousView, with: newView)
        window?.animator().setFrame(newFrame, display: true)

        NSAnimationContext.endGrouping()
    }

    @IBAction func changePredicate(_ sender: NSSearchField) {
        let searchTerm = sender.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        if searchTerm.isEmpty {
            autoCorrectController.filterPredicate = nil
        } else {
            autoCorrectController.filterPredicate = NSPredicate(
                format: "(replace CONTAINS[c] %@) OR (with CONTAINS %@)",
                searchTerm, searchTerm
            )
        }
    }
}
