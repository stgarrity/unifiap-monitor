import Foundation

class APCacheManager {
    static let shared = APCacheManager()
    
    private let cacheKey = "cachedAccessPoints"
    private let cacheTimestampKey = "cacheTimestamp"
    
    private init() {}
    
    // MARK: - Save
    
    func saveAccessPoints(_ accessPoints: [AccessPoint]) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(accessPoints)
            UserDefaults.standard.set(data, forKey: cacheKey)
            UserDefaults.standard.set(Date(), forKey: cacheTimestampKey)
        } catch {
            print("Failed to cache access points: \(error)")
        }
    }
    
    // MARK: - Retrieve
    
    func loadAccessPoints() -> [AccessPoint]? {
        guard let data = UserDefaults.standard.data(forKey: cacheKey) else {
            return nil
        }
        
        do {
            let decoder = JSONDecoder()
            let accessPoints = try decoder.decode([AccessPoint].self, from: data)
            return accessPoints
        } catch {
            print("Failed to load cached access points: \(error)")
            return nil
        }
    }
    
    // MARK: - Cache Info
    
    func getCacheTimestamp() -> Date? {
        return UserDefaults.standard.object(forKey: cacheTimestampKey) as? Date
    }
    
    func hasCachedData() -> Bool {
        return loadAccessPoints() != nil
    }
    
    func clearCache() {
        UserDefaults.standard.removeObject(forKey: cacheKey)
        UserDefaults.standard.removeObject(forKey: cacheTimestampKey)
    }
}
