import Foundation

@MainActor
final class CacheManager {
    static let shared = CacheManager()

    private var weightCache: [String: String]
    private var phoneticCache: [String: [String]]
    private var phoneticAccessOrder: [String]
    private static let phoneticCacheCapacity = 512
    private var recentBaseCache: [String: [String]]

    private static var sharedFolderURL: URL {
        guard let appSupport = FileManager.default.urls(for: .applicationSupportDirectory,
                                                         in: .userDomainMask).first else {
            fatalError("Application Support directory not found")
        }
        return appSupport
            .appendingPathComponent("OmicronLab")
            .appendingPathComponent("Avro Keyboard")
    }

    private init() {
        let folderURL = Self.sharedFolderURL
        try? FileManager.default.createDirectory(at: folderURL,
                                                   withIntermediateDirectories: true)

        let weightPath = folderURL.appendingPathComponent("weight.plist")
        if let data = try? Data(contentsOf: weightPath),
           let dict = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: String] {
            self.weightCache = dict
        } else {
            self.weightCache = [:]
        }
        self.phoneticCache = [:]
        self.phoneticAccessOrder = []
        self.recentBaseCache = [:]
    }

    // MARK: - Weight Cache
    func string(forKey key: String) -> String? { weightCache[key] }
    func removeString(forKey key: String) { weightCache.removeValue(forKey: key) }
    func setString(_ value: String, forKey key: String) { weightCache[key] = value }

    // MARK: - Phonetic Cache (LRU, capped at phoneticCacheCapacity)
    func array(forKey key: String) -> [String]? {
        guard let value = phoneticCache[key] else { return nil }
        // Move to end (most recently used)
        if let idx = phoneticAccessOrder.firstIndex(of: key) {
            phoneticAccessOrder.remove(at: idx)
        }
        phoneticAccessOrder.append(key)
        return value
    }

    func setArray(_ value: [String], forKey key: String) {
        if phoneticCache[key] != nil {
            if let idx = phoneticAccessOrder.firstIndex(of: key) {
                phoneticAccessOrder.remove(at: idx)
            }
        } else if phoneticCache.count >= Self.phoneticCacheCapacity {
            // Evict oldest entry
            let oldest = phoneticAccessOrder.removeFirst()
            phoneticCache.removeValue(forKey: oldest)
        }
        phoneticCache[key] = value
        phoneticAccessOrder.append(key)
    }

    // MARK: - Base Cache
    func removeAllBase() { recentBaseCache.removeAll() }
    func base(forKey key: String) -> [String]? { recentBaseCache[key] }
    func setBase(_ value: [String], forKey key: String) { recentBaseCache[key] = value }

    // MARK: - Persistence
    func persist() {
        let path = Self.sharedFolderURL.appendingPathComponent("weight.plist")
        do {
            let data = try PropertyListSerialization.data(
                fromPropertyList: weightCache,
                format: .xml,
                options: 0
            )
            try data.write(to: path, options: .atomic)
        } catch {
            NSLog("Failed to persist weight cache: %@", error.localizedDescription)
        }
    }
}
