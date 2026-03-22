import AppKit
import InputMethodKit
import os
import SwiftUI

// MARK: - Delegate Protocol (custom panel only)

@MainActor
protocol CandidatePanelDelegate: AnyObject {
    func candidateSelectionChanged(to candidate: String, at index: Int)
    func candidateSelected(_ candidate: String, at index: Int)
}

// MARK: - Custom NSPanel

private final class CandidateNSPanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    init() {
        super.init(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: true
        )
        level = NSWindow.Level(Int(kCGPopUpMenuWindowLevel) + 1)
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        isReleasedWhenClosed = false
    }
}

// MARK: - CandidatesPanel

@MainActor
final class CandidatesPanel {
    private static var _shared: CandidatesPanel?
    static var shared: CandidatesPanel {
        guard let instance = _shared else {
            fatalError("CandidatesPanel.initialize(with:) must be called before accessing .shared")
        }
        return instance
    }

    private static let log = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.omicronlab.avro",
        category: "CandidatesPanel"
    )

    // IMK backend
    private var imkCandidates: IMKCandidates?
    private let server: IMKServer

    // Custom backend
    private let panel: CandidateNSPanel
    private let viewModel = CandidateViewModel()
    private let hostingView: NSHostingView<CandidateView>
    private let effectView: NSVisualEffectView

    weak var delegate: CandidatePanelDelegate?

    var useCustomPanel: Bool { UserDefaults.standard.bool(for: .useCustomCandidatePanel) }

    var isVisible: Bool {
        useCustomPanel ? panel.isVisible : (imkCandidates?.isVisible() ?? false)
    }

    var panelType: Int { UserDefaults.standard.integer(for: .candidatePanelType) }

    var selectedCandidate: String? {
        guard useCustomPanel else { return nil }
        let idx = viewModel.selectedIndex
        guard idx >= 0, idx < viewModel.candidates.count else { return nil }
        return viewModel.candidates[idx]
    }

    static func initialize(with server: IMKServer) {
        _shared = CandidatesPanel(server: server)
    }

    private init(server: IMKServer) {
        self.server = server

        // Set up IMK backend
        let panelType = UserDefaults.standard.integer(for: .candidatePanelType)
        imkCandidates = IMKCandidates(
            server: server,
            panelType: IMKCandidatePanelType(panelType)
        )
        imkCandidates?.setAttributes([
            IMKCandidatesSendServerKeyEventFirst: NSNumber(value: true)
        ])
        imkCandidates?.setDismissesAutomatically(false)

        // Set up custom backend
        panel = CandidateNSPanel()

        let candidateView = CandidateView(viewModel: viewModel)
        hostingView = NSHostingView(rootView: candidateView)
        hostingView.sizingOptions = .intrinsicContentSize

        effectView = NSVisualEffectView()
        effectView.material = .popover
        effectView.blendingMode = .behindWindow
        effectView.state = .active
        effectView.wantsLayer = true
        effectView.layer?.cornerRadius = 8
        effectView.layer?.masksToBounds = true

        effectView.addSubview(hostingView)
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingView.topAnchor.constraint(equalTo: effectView.topAnchor),
            hostingView.bottomAnchor.constraint(equalTo: effectView.bottomAnchor),
            hostingView.leadingAnchor.constraint(equalTo: effectView.leadingAnchor),
            hostingView.trailingAnchor.constraint(equalTo: effectView.trailingAnchor),
        ])

        panel.contentView = effectView
    }

    func reallocate() {
        guard !useCustomPanel else { return }
        let panelType = UserDefaults.standard.integer(for: .candidatePanelType)
        imkCandidates = IMKCandidates(
            server: server,
            panelType: IMKCandidatePanelType(panelType)
        )
        imkCandidates?.setAttributes([
            IMKCandidatesSendServerKeyEventFirst: NSNumber(value: true)
        ])
        imkCandidates?.setDismissesAutomatically(false)
    }

    // MARK: - Candidate Data (custom panel)

    func updateCandidates(_ candidates: [String]) {
        viewModel.candidates = candidates
        if viewModel.selectedIndex >= candidates.count {
            viewModel.selectedIndex = 0
        }
    }

    // MARK: - IMK Backend Methods

    func imkUpdateCandidates() { imkCandidates?.update() }
    func imkShow(_ locationHint: IMKCandidatesLocationHint) { imkCandidates?.show(locationHint) }
    func imkCandidateFrame() -> NSRect { imkCandidates?.candidateFrame() ?? .zero }
    func imkSetCandidateFrameTopLeft(_ point: NSPoint) { imkCandidates?.setCandidateFrameTopLeft(point) }

    // MARK: - Selection

    func selectCandidate(at index: Int) {
        if useCustomPanel {
            guard index >= 0, index < viewModel.candidates.count else { return }
            viewModel.selectedIndex = index
            delegate?.candidateSelectionChanged(to: viewModel.candidates[index], at: index)
        }
    }

    func moveDown(_ sender: Any?) {
        if useCustomPanel {
            guard !viewModel.candidates.isEmpty else { return }
            let next = (viewModel.selectedIndex + 1) % viewModel.candidates.count
            selectCandidate(at: next)
        } else {
            imkCandidates?.moveDown(sender)
        }
    }

    func moveUp(_ sender: Any?) {
        if useCustomPanel {
            guard !viewModel.candidates.isEmpty else { return }
            let prev = (viewModel.selectedIndex - 1 + viewModel.candidates.count) % viewModel.candidates.count
            selectCandidate(at: prev)
        } else {
            imkCandidates?.moveUp(sender)
        }
    }

    func moveRight(_ sender: Any?) {
        if useCustomPanel {
            moveDown(sender)
        } else {
            imkCandidates?.moveRight(sender)
        }
    }

    func moveLeft(_ sender: Any?) {
        if useCustomPanel {
            moveUp(sender)
        } else {
            imkCandidates?.moveLeft(sender)
        }
    }

    // MARK: - Show / Hide

    func show(for client: (any IMKTextInput)?) {
        guard !viewModel.candidates.isEmpty else { hide(); return }

        hostingView.layoutSubtreeIfNeeded()
        let contentSize = hostingView.fittingSize
        let panelSize = NSSize(
            width: max(contentSize.width, 120),
            height: contentSize.height
        )

        let origin = cursorOrigin(from: client, panelHeight: panelSize.height)
        let clamped = clampToScreen(origin, panelSize: panelSize)

        panel.setFrame(NSRect(origin: clamped, size: panelSize), display: true)
        panel.orderFront(nil)
    }

    func hide() {
        if useCustomPanel {
            panel.orderOut(nil)
            viewModel.selectedIndex = 0
        } else {
            imkCandidates?.hide()
        }
    }

    // MARK: - Positioning (custom panel)

    private func cursorOrigin(from client: (any IMKTextInput)?, panelHeight: CGFloat) -> NSPoint {
        if let client {
            var lineRect = NSRect.zero
            _ = client.attributes(forCharacterIndex: 0, lineHeightRectangle: &lineRect)
            Self.log.debug("attributes → x=\(lineRect.origin.x), y=\(lineRect.origin.y), h=\(lineRect.size.height)")

            // Only use the position if it's actually on a screen
            // (web editors like Google Docs return page coordinates, not screen coordinates)
            if isOnScreen(lineRect.origin) {
                return NSPoint(
                    x: lineRect.origin.x,
                    y: lineRect.origin.y - panelHeight
                )
            }
        }

        // Fallback: position near the mouse cursor
        Self.log.debug("fallback to mouse position")
        var mouse = NSEvent.mouseLocation
        mouse.y -= 36
        return NSPoint(x: mouse.x, y: mouse.y - panelHeight)
    }

    /// Check whether a point lies within any connected screen's frame.
    ///
    /// Web editors (e.g. Google Docs) return page coordinates from
    /// `attributes(forCharacterIndex:)` instead of screen coordinates,
    /// often producing values like y=10991 that are far off-screen.
    /// This check rejects those so we can fall back to mouse position.
    ///
    /// **Potential risk**: if a web editor returns page coordinates that
    /// happen to land inside a screen's frame, we'd mis-use them as
    /// screen coordinates. In practice this is rare because macOS screen
    /// coordinates (y=0 at bottom) and web page coordinates (y=0 at top)
    /// run in opposite directions.
    private func isOnScreen(_ point: NSPoint) -> Bool {
        NSScreen.screens.contains { screen in
            let frame = screen.frame
            return point.x >= frame.minX && point.x <= frame.maxX
                && point.y >= frame.minY && point.y <= frame.maxY
        }
    }

    private func clampToScreen(_ origin: NSPoint, panelSize: NSSize) -> NSPoint {
        var point = origin

        let screen = NSScreen.screens.first { screen in
            let frame = screen.visibleFrame
            return point.x >= frame.minX && point.x <= frame.maxX
                && point.y >= frame.minY - panelSize.height && point.y <= frame.maxY
        } ?? NSScreen.main

        guard let screenFrame = screen?.visibleFrame else { return point }

        if point.y < screenFrame.minY {
            point.y = origin.y + panelSize.height + 20
        }
        if point.y + panelSize.height > screenFrame.maxY {
            point.y = screenFrame.maxY - panelSize.height
        }
        if point.x + panelSize.width > screenFrame.maxX {
            point.x = screenFrame.maxX - panelSize.width
        }
        if point.x < screenFrame.minX {
            point.x = screenFrame.minX
        }

        return point
    }
}
