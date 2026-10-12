import SwiftUI

// MARK: - General Tab

struct GeneralTab: View {
    @AppStorage("CandidatePanelType") private var candidatePanelType = 1
    @AppStorage("IncludeDictionary") private var includeDictionary = true
    @AppStorage("CommitNewLineOnEnter") private var commitNewLineOnEnter = false
    @AppStorage("UseCustomCandidatePanel") private var useCustomCandidatePanel = false

    var body: some View {
        Form {
            Picker("Suggestion List Orientation:", selection: $candidatePanelType) {
                Text("Vertical").tag(1)
                Text("Horizontal").tag(3)
            }

            Toggle("Include Dictionary Suggestions", isOn: $includeDictionary)
            Toggle("Commit new line on Enter/Return", isOn: $commitNewLineOnEnter)

            Section {
                Toggle(isOn: $useCustomCandidatePanel) {
                    Text("Use custom candidate panel")
                    HStack(spacing: 4) {
                        Text("BETA")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1.5)
                            .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 3))

                        Text("If you encounter any issues, please [report them](https://github.com/torifat/iAvro/issues).")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            } header: {
                Text("Experimental")
            }
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
    @ObservedObject private var model = AutoCorrectSearchModel()
    private let entries: [AutoCorrectEntry]

    init() {
        entries = AutoCorrect.shared.entries
            .sorted { $0.key < $1.key }
            .map { AutoCorrectEntry(replace: $0.key, with: $0.value) }
    }

    private var filteredEntries: [AutoCorrectEntry] {
        guard !model.searchText.isEmpty else { return entries }
        return entries.filter {
            $0.replace.localizedCaseInsensitiveContains(model.searchText) ||
            $0.with.contains(model.searchText)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                TextField("Search", text: $model.searchText)
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

@MainActor
private final class AutoCorrectSearchModel: ObservableObject {
    @Published var searchText = ""
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

#if canImport(PreviewsMacros)
#Preview("General") {
    GeneralTab()
}

#Preview("AutoCorrect") {
    AutoCorrectTab()
}

#Preview("Credits") {
    CreditsTab()
}
#endif
