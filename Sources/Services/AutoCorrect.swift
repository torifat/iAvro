import Foundation

@MainActor
final class AutoCorrect {
    static let shared = AutoCorrect()

    private(set) var entries: [String: String]

    private init() {
        if let path = Bundle.main.path(forResource: "autodict", ofType: "plist"),
           let dict = NSDictionary(contentsOfFile: path) as? [String: String] {
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
