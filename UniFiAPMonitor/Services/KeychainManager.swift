import Foundation
import Security

class KeychainManager {
    static let shared = KeychainManager()
    
    private let service = "com.stgarrity.UniFiAPMonitor"
    
    enum KeychainError: Error, LocalizedError {
        case itemNotFound
        case duplicateItem
        case invalidItemFormat
        case unexpectedStatus(OSStatus)
        
        var errorDescription: String? {
            switch self {
            case .itemNotFound:
                return "Keychain item not found"
            case .duplicateItem:
                return "Keychain item already exists"
            case .invalidItemFormat:
                return "Invalid data format"
            case .unexpectedStatus(let status):
                return "Keychain error: \(status) - \(SecCopyErrorMessageString(status, nil) as String? ?? "Unknown error")"
            }
        }
    }
    
    // MARK: - Save
    
    func save(password: String, account: String) throws {
        guard let passwordData = password.data(using: .utf8) else {
            throw KeychainError.invalidItemFormat
        }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: passwordData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
        ]
        
        // Try to delete existing item first
        SecItemDelete(query as CFDictionary)
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            throw KeychainError.unexpectedStatus(status)
        }
    }
    
    // MARK: - Retrieve
    
    func retrieve(account: String) throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                throw KeychainError.itemNotFound
            }
            throw KeychainError.unexpectedStatus(status)
        }
        
        guard let data = result as? Data,
              let password = String(data: data, encoding: .utf8) else {
            throw KeychainError.invalidItemFormat
        }
        
        return password
    }
    
    // MARK: - Delete
    
    func delete(account: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unexpectedStatus(status)
        }
    }
    
    // MARK: - Convenience methods for UniFi credentials
    
    func saveUniFiCredentials(url: String, username: String, password: String) throws {
        try save(password: url, account: "unifi.url")
        try save(password: username, account: "unifi.username")
        try save(password: password, account: "unifi.password")
    }
    
    func retrieveUniFiCredentials() -> (url: String?, username: String?, password: String?) {
        let url = try? retrieve(account: "unifi.url")
        let username = try? retrieve(account: "unifi.username")
        let password = try? retrieve(account: "unifi.password")
        return (url, username, password)
    }
    
    func deleteUniFiCredentials() throws {
        try delete(account: "unifi.url")
        try delete(account: "unifi.username")
        try delete(account: "unifi.password")
    }
}
