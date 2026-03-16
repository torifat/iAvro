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
            let defaults = UserDefaults.standard

            if CandidatesPanel.shared.panelType != defaults.integer(for: .candidatePanelType) {
                CandidatesPanel.shared.reallocate()
            }
            CandidatesPanel.shared.updateCandidates()
            CandidatesPanel.shared.show(kIMKLocateCandidatesBelowHint)

            if prevSelected > -1 {
                for _ in 0..<prevSelected {
                    if CandidatesPanel.shared.panelType == kIMKSingleColumnScrollingCandidatePanel {
                        CandidatesPanel.shared.moveDown(self)
                    } else if CandidatesPanel.shared.panelType == kIMKSingleRowSteppingCandidatePanel {
                        CandidatesPanel.shared.moveRight(self)
                    }
                }
            }
        } else {
            CandidatesPanel.shared.hide()
        }
    }

    // MARK: - IMK Callbacks

    @objc override func candidates(_ sender: Any!) -> [Any]! {
        let candidates = currentCandidates
        return candidates
    }

    @objc override func candidateSelectionChanged(_ candidateString: NSAttributedString!) {
        guard let candidateString else { return }
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

                    // Reverse suffix caching
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
        guard let candidateString else { return }
        currentClient?.insertText(candidateString.string, replacementRange: NSRange(location: NSNotFound, length: 0))

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
            if !currentCandidates.isEmpty {
                candidateSelected(NSAttributedString(string: currentCandidates[selectedCandidateIndex]))
            }
            return false
        } else {
            composedBuffer += string
            findCurrentCandidates()
            updateComposition()
            updateCandidatesPanel()
            return true
        }
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

    @objc override func didCommand(by aSelector: Selector, client sender: Any!) -> Bool {
        self.currentClient = sender as? (any IMKTextInput)
        if responds(to: aSelector) && !composedBuffer.isEmpty {
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
        if !currentCandidates.isEmpty {
            candidateSelected(NSAttributedString(string: currentCandidates[selectedCandidateIndex]))
            currentClient?.insertText(string, replacementRange: NSRange(location: NSNotFound, length: 0))
        } else {
            NSSound.beep()
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
