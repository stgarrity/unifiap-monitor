import Foundation

class UniFiAPIClient: NSObject {
    static let shared = UniFiAPIClient()
    
    private var sessionCookies: [HTTPCookie] = []
    private var controllerType: ControllerType = .unknown
    
    enum ControllerType {
        case regular  // Regular UniFi Controller
        case unifiOS  // UniFi OS (UDM/Cloud Key Gen2+)
        case unknown
    }
    
    enum UniFiError: LocalizedError {
        case invalidURL
        case missingCredentials
        case authenticationFailed
        case networkError(Error)
        case invalidResponse
        case decodingError(Error)
        case noDevicesFound
        
        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "Invalid controller URL"
            case .missingCredentials:
                return "Missing credentials. Please configure in Preferences."
            case .authenticationFailed:
                return "Authentication failed. Please check your credentials."
            case .networkError(let error):
                return "Network error: \(error.localizedDescription)"
            case .invalidResponse:
                return "Invalid response from controller"
            case .decodingError(let error):
                return "Failed to parse response: \(error.localizedDescription)"
            case .noDevicesFound:
                return "No access points found"
            }
        }
    }
    
    // MARK: - Session Management
    
    private lazy var urlSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.httpCookieAcceptPolicy = .always
        config.httpShouldSetCookies = true
        config.httpCookieStorage = HTTPCookieStorage.shared
        return URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }()
    
    // MARK: - Public Methods
    
    func login(url: String, username: String, password: String) async throws {
        guard let baseURL = URL(string: url) else {
            throw UniFiError.invalidURL
        }
        
        // Clear any existing cookies
        sessionCookies.removeAll()
        if let cookies = HTTPCookieStorage.shared.cookies {
            for cookie in cookies {
                HTTPCookieStorage.shared.deleteCookie(cookie)
            }
        }
        
        // Try UniFi OS first, then regular controller
        do {
            try await loginUniFiOS(baseURL: baseURL, username: username, password: password)
            controllerType = .unifiOS
        } catch {
            try await loginRegular(baseURL: baseURL, username: username, password: password)
            controllerType = .regular
        }
    }
    
    func fetchAccessPoints(url: String, site: String = "default") async throws -> [AccessPoint] {
        guard let baseURL = URL(string: url) else {
            throw UniFiError.invalidURL
        }
        
        let deviceURL: URL
        switch controllerType {
        case .unifiOS:
            deviceURL = baseURL.appendingPathComponent("proxy/network/api/s/\(site)/stat/device")
        case .regular:
            deviceURL = baseURL.appendingPathComponent("api/s/\(site)/stat/device")
        case .unknown:
            // Try UniFi OS path first
            deviceURL = baseURL.appendingPathComponent("proxy/network/api/s/\(site)/stat/device")
        }
        
        var request = URLRequest(url: deviceURL)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await urlSession.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw UniFiError.invalidResponse
        }
        
        // If we get 401/403, try to re-authenticate
        if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
            let credentials = KeychainManager.shared.retrieveUniFiCredentials()
            guard let url = credentials.url,
                  let username = credentials.username,
                  let password = credentials.password else {
                throw UniFiError.missingCredentials
            }
            try await login(url: url, username: username, password: password)
            return try await fetchAccessPoints(url: url, site: site)
        }
        
        guard httpResponse.statusCode == 200 else {
            throw UniFiError.invalidResponse
        }
        
        do {
            let response = try JSONDecoder().decode(UniFiDeviceResponse.self, from: data)
            let accessPoints = response.data
                .filter { $0.type == "uap" }
                .map { $0.toAccessPoint() }
            
            guard !accessPoints.isEmpty else {
                throw UniFiError.noDevicesFound
            }
            
            return accessPoints
        } catch let decodingError {
            throw UniFiError.decodingError(decodingError)
        }
    }
    
    func testConnection(url: String, username: String, password: String) async throws -> [AccessPoint] {
        try await login(url: url, username: username, password: password)
        return try await fetchAccessPoints(url: url)
    }
    
    func findAccessPoint(byBSSID bssid: String, accessPoints: [AccessPoint]) -> AccessPoint? {
        let normalizedBSSID = bssid.replacingOccurrences(of: ":", with: "").lowercased()
        
        // First try exact match
        if let exactMatch = accessPoints.first(where: { $0.normalizedMAC == normalizedBSSID }) {
            return exactMatch
        }
        
        // UniFi APs broadcast multiple BSSIDs (one per SSID), where only the last octet differs
        // Try matching on first 5 octets (first 10 hex characters)
        if normalizedBSSID.count >= 10 {
            let bssidPrefix = String(normalizedBSSID.prefix(10))
            return accessPoints.first { ap in
                let apPrefix = String(ap.normalizedMAC.prefix(10))
                return apPrefix == bssidPrefix
            }
        }
        
        return nil
    }
    
    // MARK: - Private Methods
    
    private func loginUniFiOS(baseURL: URL, username: String, password: String) async throws {
        let loginURL = baseURL.appendingPathComponent("api/auth/login")
        
        var request = URLRequest(url: loginURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let loginData = ["username": username, "password": password, "remember": false] as [String : Any]
        request.httpBody = try JSONSerialization.data(withJSONObject: loginData)
        
        let (_, response) = try await urlSession.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw UniFiError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw UniFiError.authenticationFailed
        }
    }
    
    private func loginRegular(baseURL: URL, username: String, password: String) async throws {
        let loginURL = baseURL.appendingPathComponent("api/login")
        
        var request = URLRequest(url: loginURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let loginData = ["username": username, "password": password]
        request.httpBody = try JSONEncoder().encode(loginData)
        
        let (_, response) = try await urlSession.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw UniFiError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw UniFiError.authenticationFailed
        }
    }
}

// MARK: - URLSessionDelegate

extension UniFiAPIClient: URLSessionDelegate {
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        // Accept self-signed certificates for local UniFi controllers
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
           let trust = challenge.protectionSpace.serverTrust {
            let credential = URLCredential(trust: trust)
            completionHandler(.useCredential, credential)
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
}

// MARK: - Response Models

private struct UniFiDeviceResponse: Codable {
    let data: [UniFiDevice]
}

private struct UniFiDevice: Codable {
    let id: String
    let mac: String
    let name: String?
    let model: String
    let type: String
    let state: Int
    let adopted: Bool
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case mac
        case name
        case model
        case type
        case state
        case adopted
    }
    
    func toAccessPoint() -> AccessPoint {
        return AccessPoint(
            id: id,
            mac: mac,
            name: name ?? "",
            model: model,
            state: state,
            adopted: adopted
        )
    }
}
