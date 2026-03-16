import InputMethodKit

@MainActor
final class CandidatesPanel {
    private static var _shared: CandidatesPanel?
    static var shared: CandidatesPanel {
        guard let instance = _shared else {
            fatalError("CandidatesPanel.initialize(with:) must be called before accessing .shared")
        }
        return instance
    }

    private var candidates: IMKCandidates
    private let server: IMKServer

    static func initialize(with server: IMKServer) {
        _shared = CandidatesPanel(server: server)
    }

    private init(server: IMKServer) {
        self.server = server
        let panelType = UserDefaults.standard.integer(for: .candidatePanelType)
        self.candidates = IMKCandidates(
            server: server,
            panelType: IMKCandidatePanelType(panelType)
        )
        candidates.setAttributes([
            IMKCandidatesSendServerKeyEventFirst: NSNumber(value: true)
        ])
        candidates.setDismissesAutomatically(false)
    }

    func reallocate() {
        let panelType = UserDefaults.standard.integer(for: .candidatePanelType)
        self.candidates = IMKCandidates(
            server: server,
            panelType: IMKCandidatePanelType(panelType)
        )
        candidates.setAttributes([
            IMKCandidatesSendServerKeyEventFirst: NSNumber(value: true)
        ])
        candidates.setDismissesAutomatically(false)
    }

    var panelType: Int { candidates.panelType() }
    var isVisible: Bool { candidates.isVisible() }

    func updateCandidates() { candidates.update() }
    func show(_ locationHint: IMKCandidatesLocationHint) { candidates.show(locationHint) }
    func hide() { candidates.hide() }
    func moveUp(_ sender: Any?) { candidates.moveUp(sender) }
    func moveDown(_ sender: Any?) { candidates.moveDown(sender) }
    func moveLeft(_ sender: Any?) { candidates.moveLeft(sender) }
    func moveRight(_ sender: Any?) { candidates.moveRight(sender) }
}
