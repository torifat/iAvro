import SwiftUI

// MARK: - General Tab

struct GeneralTab: View {
    @AppStorage("CandidatePanelType") private var candidatePanelType = 1
    @AppStorage("IncludeDictionary") private var includeDictionary = true
    @AppStorage("CommitNewLineOnEnter") private var commitNewLineOnEnter = false

    var body: some View {
        Form {
            Picker("Suggestion List Orientation:", selection: $candidatePanelType) {
                Text("Vertical").tag(1)
                Text("Horizontal").tag(3)
            }

            Toggle("Include Dictionary Suggestions", isOn: $includeDictionary)
            Toggle("Commit new line on Enter/Return", isOn: $commitNewLineOnEnter)
        }
        .formStyle(.grouped)
        .frame(width: 450)
    }
}

// MARK: - AutoCorrect Tab

private struct AutoCorrectEntry: Identifiable {
    let replace: String
    let with: String
    var id: String { replace }
}

struct AutoCorrectTab: View {
    @State private var searchText = ""
    private let entries: [AutoCorrectEntry]

    init() {
        entries = AutoCorrect.shared.entries
            .sorted { $0.key < $1.key }
            .map { AutoCorrectEntry(replace: $0.key, with: $0.value) }
    }

    private var filteredEntries: [AutoCorrectEntry] {
        guard !searchText.isEmpty else { return entries }
        return entries.filter {
            $0.replace.localizedCaseInsensitiveContains(searchText) ||
            $0.with.contains(searchText)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                TextField("Search", text: $searchText)
                    .textFieldStyle(.roundedBorder)
            }
            .padding(.horizontal)
            .padding(.top, 12)
            .padding(.bottom, 8)

            Table(filteredEntries) {
                TableColumn("Replace", value: \.replace)
                TableColumn("With", value: \.with)
            }

            HStack {
                Spacer()
                Text("\(filteredEntries.count) Items")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
            .padding(.vertical, 6)
        }
    }
}

// MARK: - Credits Tab

struct CreditsTab: View {
    var body: some View {
        CreditsTextView()
    }
}

/// Wraps NSTextView to display the Credits.rtfd bundle (rich text with embedded images).
private struct CreditsTextView: NSViewRepresentable {
    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        let textView = scrollView.documentView as! NSTextView

        textView.isEditable = false
        textView.isSelectable = true
        textView.backgroundColor = .white

        if let path = Bundle.main.path(forResource: "Credits", ofType: "rtfd") {
            textView.readRTFD(fromFile: path)
            textView.scrollToBeginningOfDocument(nil)
        }

        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {}
}

// MARK: - Previews

#Preview("General") {
    GeneralTab()
}

#Preview("AutoCorrect") {
    AutoCorrectTab()
}

#Preview("Credits") {
    CreditsTab()
}
