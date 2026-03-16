import Foundation

extension UserDefaults {
    enum Key: String {
        case includeDictionary = "IncludeDictionary"
        case candidatePanelType = "CandidatePanelType"
        case commitNewLineOnEnter = "CommitNewLineOnEnter"
    }

    func bool(for key: Key) -> Bool { bool(forKey: key.rawValue) }
    func integer(for key: Key) -> Int { integer(forKey: key.rawValue) }
}
