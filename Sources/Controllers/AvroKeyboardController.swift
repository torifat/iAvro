import Cocoa
@preconcurrency import InputMethodKit

@objc(AvroKeyboardController)
@MainActor
class AvroKeyboardController: IMKInputController, @unchecked Sendable {

    nonisolated(unsafe) private var currentClient: (any IMKTextInput)?
    private var prevSelected: Int = -1
    private var composedBuffer = ""
    private var currentCandidates: [String] = []
    private var selectedCandidateIndex: Int = 0
    private var prefixStr: String = ""
    private var termStr: String = ""
    private var suffixStr: String = ""
    private var usedArrowKeys = false

    @objc override init!(server: IMKServer!, delegate: Any!, client inputClient: Any!) {
        super.init(server: server, delegate: delegate, client: inputClient)
        self.currentClient = inputClient as? (any IMKTextInput)
    }

    @objc override func activateServer(_ sender: Any!) {
        super.activateServer(sender)
        self.currentClient = sender as? (any IMKTextInput)
        CandidatesPanel.shared.delegate = self
    }

    @objc override func deactivateServer(_ sender: Any!) {
        commitComposition(sender)
        super.deactivateServer(sender)
    }

    // MARK: - Candidate Finding

    private func findCurrentCandidates() {
        currentCandidates.removeAll()
        guard !composedBuffer.isEmpty else { return }

        let regexPattern = "(^(?::`|\\.`|[-\\]\\\\~!@#&*()_=+\\[{}'\";<>/?|.,])*?(?=(?:,{2,}))|^(?::`|\\.`|[-\\]\\\\~!@#&*()_=+\\[{}'\";<>/?|.,])*)(.*?(?:,,)*)((?::`|\\.`|[-\\]\\\\~!@#&*()_=+\\[{}'\";<>/?|.,])*$)"

        guard let regex = try? NSRegularExpression(pattern: regexPattern),
              let match = regex.firstMatch(
                  in: composedBuffer,
                  range: NSRange(composedBuffer.startIndex..., in: composedBuffer)),
              match.numberOfRanges > 3 else {
            return
        }

        let nsString = composedBuffer as NSString
        self.prefixStr = AvroParser.shared.parse(nsString.substring(with: match.range(at: 1)))
        self.termStr = nsString.substring(with: match.range(at: 2))
        self.suffixStr = AvroParser.shared.parse(nsString.substring(with: match.range(at: 3)))

        let suggestions = SuggestionEngine.shared.getList(self.termStr)
        let useDict = UserDefaults.standard.bool(for: .includeDictionary)

        if !suggestions.isEmpty {
            currentCandidates = suggestions

            var prevString: String?
            if useDict {
                prevSelected = -1
                prevString = CacheManager.shared.string(forKey: self.termStr)
            }

            for i in 0..<currentCandidates.count {
                let item = currentCandidates[i]
                if useDict, let prev = prevString, item == prev {
                    prevSelected = i
                }
                currentCandidates[i] = "\(self.prefixStr)\(item)\(self.suffixStr)"
            }

            // Emoticons
            if composedBuffer != self.termStr && useDict {
                if let smiley = AutoCorrect.shared.find(composedBuffer) {
                    currentCandidates.insert(smiley, at: 0)
                }
            }
        } else {
            currentCandidates.append(self.prefixStr)
        }
    }

    internal override func updateComposition() {
        currentClient?.setMarkedText(
            composedBuffer,
            selectionRange: NSRange(location: composedBuffer.utf16.count, length: 0),
            replacementRange: NSRange(location: NSNotFound, length: NSNotFound)
        )
    }

    private func updateCandidatesPanel() {
        if !currentCandidates.isEmpty {
            if CandidatesPanel.shared.useCustomPanel {
                CandidatesPanel.shared.updateCandidates(currentCandidates)
                CandidatesPanel.shared.show(for: currentClient)

                if prevSelected > -1 {
                    CandidatesPanel.shared.selectCandidate(at: prevSelected)
                }
            } else {
                let defaults = UserDefaults.standard
                if CandidatesPanel.shared.panelType != defaults.integer(for: .candidatePanelType) {
                    CandidatesPanel.shared.reallocate()
                }
                CandidatesPanel.shared.imkUpdateCandidates()
                CandidatesPanel.shared.imkShow(kIMKLocateCandidatesBelowHint)

            // Fallback: some web editors (e.g. Google Docs) report cursor
            // position (0,0), placing the panel at the bottom-left corner.
            // Reposition near the mouse cursor instead.
            let frame = CandidatesPanel.shared.imkCandidateFrame()

            if frame.origin.x < 1, frame.origin.y < 1 {
                var point = NSEvent.mouseLocation
                point.y -= 36
                CandidatesPanel.shared.imkSetCandidateFrameTopLeft(point)
            }

            if prevSelected > -1 {
                for _ in 0..<prevSelected {
                    if CandidatesPanel.shared.panelType == kIMKSingleColumnScrollingCandidatePanel {
                        CandidatesPanel.shared.moveDown(self)
                    } else if CandidatesPanel.shared.panelType == kIMKSingleRowSteppingCandidatePanel {
                        CandidatesPanel.shared.moveRight(self)
                    }
                }
            }
            } // end IMK else
        } else {
            CandidatesPanel.shared.hide()
        }
    }

    // MARK: - IMK Candidate Callbacks (used when custom panel is off)

    @objc override func candidates(_ sender: Any!) -> [Any]! {
        currentCandidates
    }

    @objc override func candidateSelectionChanged(_ candidateString: NSAttributedString!) {
        guard !CandidatesPanel.shared.useCustomPanel, let candidateString else { return }
        if UserDefaults.standard.bool(for: .includeDictionary) {
            if !termStr.isEmpty {
                let isFirst = candidateString.string == currentCandidates.first
                if !(isFirst && prevSelected == -1) {
                    let prefLen = (prefixStr as NSString).length
                    let sufLen = (suffixStr as NSString).length
                    let range = NSRange(
                        location: prefLen,
                        length: candidateString.length - (prefLen + sufLen)
                    )
                    CacheManager.shared.setString(
                        (candidateString.string as NSString).substring(with: range),
                        forKey: termStr
                    )

                    if let tmpArray = CacheManager.shared.base(forKey: candidateString.string),
                       tmpArray.count > 1 {
                        CacheManager.shared.setString(tmpArray[1], forKey: tmpArray[0])
                    }
                }
            }
        }
        selectedCandidateIndex = currentCandidates.firstIndex(of: candidateString.string) ?? 0
    }

    @objc override func candidateSelected(_ candidateString: NSAttributedString!) {
        guard !CandidatesPanel.shared.useCustomPanel, let candidateString else { return }
        currentClient?.insertText(candidateString.string, replacementRange: NSRange(location: NSNotFound, length: 0))

        clearCompositionBuffer()
        currentCandidates.removeAll()
        updateCandidatesPanel()

        usedArrowKeys = false
        if UserDefaults.standard.bool(for: .includeDictionary) {
            CacheManager.shared.persist()
        }
    }

    // MARK: - Candidate Actions

    private func commitCandidate(_ candidate: String) {
        currentClient?.insertText(candidate, replacementRange: NSRange(location: NSNotFound, length: 0))

        clearCompositionBuffer()
        currentCandidates.removeAll()
        updateCandidatesPanel()

        usedArrowKeys = false
        if UserDefaults.standard.bool(for: .includeDictionary) {
            CacheManager.shared.persist()
        }
    }

    @objc override func commitComposition(_ sender: Any!) {
        guard !composedBuffer.isEmpty else { return }

        (sender as? IMKTextInput)?.insertText(composedBuffer, replacementRange: NSRange(location: NSNotFound, length: 0))

        clearCompositionBuffer()
        currentCandidates.removeAll()
        updateCandidatesPanel()
    }

    @objc override func composedString(_ sender: Any!) -> Any! {
        let buffer = composedBuffer
        return NSAttributedString(string: buffer)
    }

    private func clearCompositionBuffer() {
        composedBuffer = ""
        currentClient?.setMarkedText(
            "",
            selectionRange: NSRange(location: 0, length: 0),
            replacementRange: NSRange(location: NSNotFound, length: NSNotFound)
        )
    }

    // MARK: - Input Handling

    @objc override func inputText(_ string: String!, client sender: Any!) -> Bool {
        self.currentClient = sender as? (any IMKTextInput)

        if string == " " {
            if CandidatesPanel.shared.useCustomPanel {
                if let candidate = CandidatesPanel.shared.selectedCandidate {
                    commitCandidate(candidate)
                }
            } else if !currentCandidates.isEmpty {
                candidateSelected(NSAttributedString(string: currentCandidates[selectedCandidateIndex]))
            }
            return false
        }

        // Number key selection (1-9) when custom panel is visible
        if CandidatesPanel.shared.useCustomPanel,
           CandidatesPanel.shared.isVisible,
           let digit = string.first, digit >= "1", digit <= "9" {
            let index = Int(String(digit))! - 1
            if index < currentCandidates.count {
                commitCandidate(currentCandidates[index])
                return true
            }
        }

        composedBuffer += string
        findCurrentCandidates()
        updateComposition()
        updateCandidatesPanel()
        return true
    }

    @objc func deleteBackward(_ sender: Any?) {
        guard !composedBuffer.isEmpty else { return }
        composedBuffer.removeLast()
        findCurrentCandidates()
        updateComposition()
        updateCandidatesPanel()
    }

    @objc func insertTab(_ sender: Any?) {
        commitText("\t")
    }

    @objc func insertNewline(_ sender: Any?) {
        if UserDefaults.standard.bool(for: .commitNewLineOnEnter) {
            commitText("\n")
        } else {
            commitText("")
        }
    }

    @objc func moveUp(_ sender: Any?) {
        if CandidatesPanel.shared.isVisible {
            usedArrowKeys = true
            CandidatesPanel.shared.moveUp(self)
        }
    }

    @objc func moveDown(_ sender: Any?) {
        if CandidatesPanel.shared.isVisible {
            usedArrowKeys = true
            CandidatesPanel.shared.moveDown(self)
        }
    }

    @objc func moveLeft(_ sender: Any?) {
        if CandidatesPanel.shared.isVisible {
            usedArrowKeys = true
            CandidatesPanel.shared.moveLeft(self)
        }
    }

    @objc func moveRight(_ sender: Any?) {
        if CandidatesPanel.shared.isVisible {
            usedArrowKeys = true
            CandidatesPanel.shared.moveRight(self)
        }
    }

    @objc func cancelOperation(_ sender: Any?) {
        clearCompositionBuffer()
        currentCandidates.removeAll()
        CandidatesPanel.shared.hide()
    }

    @objc override func didCommand(by aSelector: Selector, client sender: Any!) -> Bool {
        self.currentClient = sender as? (any IMKTextInput)
        guard !composedBuffer.isEmpty else { return false }

        // Escape: cancel composition (both modes)
        if aSelector == #selector(cancelOperation(_:)) {
            cancelOperation(sender)
            return true
        }

        // All navigable commands
        if responds(to: aSelector) {
            if aSelector == #selector(insertTab(_:)) ||
               aSelector == #selector(insertNewline(_:)) ||
               aSelector == #selector(deleteBackward(_:)) ||
               aSelector == #selector(moveLeft(_:)) ||
               aSelector == #selector(moveRight(_:)) ||
               aSelector == #selector(moveUp(_:)) ||
               aSelector == #selector(moveDown(_:)) {
                perform(aSelector, with: sender)
                return true
            }
        }
        return false
    }

    private func commitText(_ string: String) {
        if CandidatesPanel.shared.useCustomPanel {
            if let candidate = CandidatesPanel.shared.selectedCandidate {
                commitCandidate(candidate)
                if !string.isEmpty {
                    currentClient?.insertText(string, replacementRange: NSRange(location: NSNotFound, length: 0))
                }
            } else {
                NSSound.beep()
            }
        } else {
            if !currentCandidates.isEmpty {
                candidateSelected(NSAttributedString(string: currentCandidates[selectedCandidateIndex]))
                currentClient?.insertText(string, replacementRange: NSRange(location: NSNotFound, length: 0))
            } else {
                NSSound.beep()
            }
        }
    }

    @objc override func menu() -> NSMenu! {
        let appMenu = (NSApp.delegate as? AppDelegate)?.menu
        return appMenu
    }

    @objc override func showPreferences(_ sender: Any?) {
        guard let appDelegate = NSApp.delegate as? AppDelegate else { return }
        appDelegate.imPref?.showPreferencesWindow()
    }
}

// MARK: - CandidatePanelDelegate

extension AvroKeyboardController: CandidatePanelDelegate {
    func candidateSelectionChanged(to candidate: String, at index: Int) {
        if UserDefaults.standard.bool(for: .includeDictionary) {
            if !termStr.isEmpty {
                let isFirst = candidate == currentCandidates.first
                if !(isFirst && prevSelected == -1) {
                    let prefLen = (prefixStr as NSString).length
                    let sufLen = (suffixStr as NSString).length
                    let candidateNS = candidate as NSString
                    let range = NSRange(
                        location: prefLen,
                        length: candidateNS.length - (prefLen + sufLen)
                    )
                    CacheManager.shared.setString(
                        candidateNS.substring(with: range),
                        forKey: termStr
                    )

                    if let tmpArray = CacheManager.shared.base(forKey: candidate),
                       tmpArray.count > 1 {
                        CacheManager.shared.setString(tmpArray[1], forKey: tmpArray[0])
                    }
                }
            }
        }
        selectedCandidateIndex = index
    }

    func candidateSelected(_ candidate: String, at index: Int) {
        commitCandidate(candidate)
    }
}
