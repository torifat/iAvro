import Foundation

@MainActor
final class AutoCorrect {
    static let shared = AutoCorrect()

    private(set) var entries: [String: String]

    private init() {
        if let url = Bundle.main.url(forResource: "autodict", withExtension: "plist"),
           let data = try? Data(contentsOf: url),
           let dict = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: String] {
            self.entries = dict
        } else {
            self.entries = [:]
        }
    }

    func find(_ term: String) -> String? {
        let fixed = AvroParser.shared.fix(term)
        return entries[fixed]
    }
}
