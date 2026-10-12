import Foundation
import SQLite3

final class Database: @unchecked Sendable {
    static let shared = Database()

    private let db: [String: [String]]
    private let suffixes: [String: String]
    private var regexCache: [String: NSRegularExpression] = [:]

    private init() {
        guard let filePath = Bundle.main.path(forResource: "database", ofType: "db3") else {
            fatalError("database.db3 not found in bundle")
        }

        var dbPointer: OpaquePointer?
        guard sqlite3_open_v2(filePath, &dbPointer, SQLITE_OPEN_READONLY, nil) == SQLITE_OK,
              let dbHandle = dbPointer else {
            fatalError("Failed to open database.db3")
        }
        defer { sqlite3_close(dbHandle) }

        let tableNames = [
            "A", "AA", "B", "BH", "C", "CH", "D", "Dd", "Ddh", "Dh",
            "E", "G", "Gh", "H", "I", "II", "J", "JH", "K", "KH",
            "Khandatta", "L", "M", "N", "NGA", "NN", "NYA", "O", "OI",
            "OU", "P", "PH", "R", "RR", "RRH", "RRI", "S", "SH", "SS",
            "T", "TH", "TT", "TTH", "U", "UU", "Y", "Z"
        ]

        var loadedDB: [String: [String]] = [:]
        for name in tableNames {
            loadedDB[name.lowercased()] = Self.loadTable(name: name, from: dbHandle)
        }
        self.db = loadedDB
        self.suffixes = Self.loadSuffixTable(from: dbHandle)
    }

    private static func loadTable(name: String, from dbHandle: OpaquePointer) -> [String] {
        var items: [String] = []
        let query = "SELECT Words FROM \(name)"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(dbHandle, query, -1, &stmt, nil) == SQLITE_OK else { return items }
        defer { sqlite3_finalize(stmt) }

        while sqlite3_step(stmt) == SQLITE_ROW {
            if let cString = sqlite3_column_text(stmt, 0) {
                items.append(String(cString: cString))
            }
        }
        return items
    }

    private static func loadSuffixTable(from dbHandle: OpaquePointer) -> [String: String] {
        var result: [String: String] = [:]
        let query = "SELECT English, Bangla FROM Suffix"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(dbHandle, query, -1, &stmt, nil) == SQLITE_OK else { return result }
        defer { sqlite3_finalize(stmt) }

        while sqlite3_step(stmt) == SQLITE_ROW {
            if let eng = sqlite3_column_text(stmt, 0), let bng = sqlite3_column_text(stmt, 1) {
                result[String(cString: eng)] = String(cString: bng)
            }
        }
        return result
    }

    func find(term: String) -> [String] {
        guard let lmc = term.lowercased().first else { return [] }
        let tables = Self.tableLookup[lmc] ?? []
        let regexPattern = "^\(RegexParser.shared.parse(term))$"

        let regex: NSRegularExpression
        if let cached = regexCache[regexPattern] {
            regex = cached
        } else {
            guard let compiled = try? NSRegularExpression(pattern: regexPattern) else {
                return []
            }
            regexCache[regexPattern] = compiled
            regex = compiled
        }

        var suggestions = Set<String>()
        for tableName in tables {
            guard let tableData = db[tableName] else { continue }
            for word in tableData {
                let range = NSRange(word.startIndex..., in: word)
                if regex.firstMatch(in: word, range: range) != nil {
                    suggestions.insert(word)
                }
            }
        }
        return Array(suggestions)
    }

    func banglaForSuffix(_ suffix: String) -> String? {
        suffixes[suffix]
    }

    private static let tableLookup: [Character: [String]] = [
        "a": ["a", "aa", "e", "oi", "o", "nya", "y"],
        "b": ["b", "bh"],
        "c": ["c", "ch", "k"],
        "d": ["d", "dh", "dd", "ddh"],
        "e": ["i", "ii", "e", "y"],
        "f": ["ph"],
        "g": ["g", "gh", "j"],
        "h": ["h"],
        "i": ["i", "ii", "y"],
        "j": ["j", "jh", "z"],
        "k": ["k", "kh"],
        "l": ["l"],
        "m": ["h", "m"],
        "n": ["n", "nya", "nga", "nn"],
        "o": ["a", "u", "uu", "oi", "o", "ou", "y"],
        "p": ["p", "ph"],
        "q": ["k"],
        "r": ["rri", "h", "r", "rr", "rrh"],
        "s": ["s", "sh", "ss"],
        "t": ["t", "th", "tt", "tth", "khandatta"],
        "u": ["u", "uu", "y"],
        "v": ["bh"],
        "w": ["o"],
        "x": ["e", "k"],
        "y": ["i", "y"],
        "z": ["h", "j", "jh", "z"],
    ]
}
