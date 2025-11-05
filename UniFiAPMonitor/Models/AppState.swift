import Foundation
import SwiftUI

@MainActor
class AppState: ObservableObject {
    @Published var currentAccessPoint: AccessPoint?
    @Published var currentSSID: String?
    @Published var currentBSSID: String?
    @Published var connectionState: ConnectionState = .unknown
    @Published var lastUpdated: Date?
    @Published var errorMessage: String?
    @Published var isRefreshing = false
    
    private var accessPoints: [AccessPoint] = []
    private var refreshTimer: Timer?
    private let refreshInterval: TimeInterval = 30 // 30 seconds
    
    weak var wifiManager: WiFiManager?
    weak var locationManager: LocationManager?
    
    enum ConnectionState {
        case connected      // Connected to home AP
        case away          // Connected to WiFi but not home
        case notConnected  // Not connected to WiFi
        case error         // Error state
        case unknown       // Initial/unknown state
        
        var icon: String {
            switch self {
            case .connected:
                return "wifi.circle.fill"
            case .away:
                return "wifi.circle"
            case .notConnected:
                return "wifi.slash"
            case .error:
                return "exclamationmark.triangle.fill"
            case .unknown:
                return "wifi"
            }
        }
        
        var displayText: String {
            switch self {
            case .connected:
                return "Connected"
            case .away:
                return "Away from home"
            case .notConnected:
                return "Not connected"
            case .error:
                return "Error"
            case .unknown:
                return "Checking..."
            }
        }
    }
    
    init() {
        Task { @MainActor in
            startPeriodicRefresh()
        }
    }
    
    // No deinit needed - timer will be invalidated when object is deallocated
    
    // MARK: - Public Methods
    
    func refresh() async {
        guard !isRefreshing else { return }
        
        isRefreshing = true
        errorMessage = nil
        
        // Check location permission
        guard let locationManager = locationManager,
              locationManager.authorizationStatus == .authorizedAlways else {
            connectionState = .error
            errorMessage = "Location permission required for WiFi BSSID access"
            isRefreshing = false
            return
        }
        
        do {
            // Get WiFi info from the shared WiFiManager
            guard let wifiManager = wifiManager else {
                connectionState = .error
                errorMessage = "WiFi manager not available"
                isRefreshing = false
                return
            }
            
            wifiManager.getCurrentWiFiInfo()
            
            currentSSID = wifiManager.currentSSID
            currentBSSID = wifiManager.currentBSSID
            
            // If no WiFi, set state and return
            guard let bssid = currentBSSID else {
                connectionState = .notConnected
                currentAccessPoint = nil
                lastUpdated = Date()
                isRefreshing = false
                return
            }
            
            // Fetch access points from UniFi if we have credentials
            let credentials = KeychainManager.shared.retrieveUniFiCredentials()
            guard let url = credentials.url,
                  let username = credentials.username,
                  let password = credentials.password else {
                connectionState = .error
                errorMessage = "No UniFi credentials configured"
                isRefreshing = false
                return
            }
            
            // Try to use cached AP list first, or fetch new one
            if accessPoints.isEmpty {
                try await fetchAccessPoints(url: url, username: username, password: password)
            }
            
            // Match current BSSID to AP list
            print("DEBUG: Attempting to match BSSID: \(bssid)")
            print("DEBUG: Normalized BSSID: \(bssid.replacingOccurrences(of: ":", with: "").lowercased())")
            print("DEBUG: Number of APs in list: \(accessPoints.count)")
            
            if let matchedAP = UniFiAPIClient.shared.findAccessPoint(byBSSID: bssid, accessPoints: accessPoints) {
                print("DEBUG: ✅ Matched AP: \(matchedAP.displayName)")
                currentAccessPoint = matchedAP
                connectionState = .connected
            } else {
                print("DEBUG: ❌ No match found")
                print("DEBUG: Available normalized MACs:")
                for ap in accessPoints {
                    print("  - \(ap.displayName): \(ap.normalizedMAC)")
                }
                // Connected to WiFi but not a home AP
                currentAccessPoint = nil
                connectionState = .away
            }
            
            lastUpdated = Date()
            
        } catch {
            connectionState = .error
            errorMessage = error.localizedDescription
        }
        
        isRefreshing = false
    }
    
    func forceRefresh() async {
        // Clear cache and refresh
        accessPoints = []
        await refresh()
    }
    
    // MARK: - Private Methods
    
    private func fetchAccessPoints(url: String, username: String, password: String) async throws {
        try await UniFiAPIClient.shared.login(url: url, username: username, password: password)
        accessPoints = try await UniFiAPIClient.shared.fetchAccessPoints(url: url)
    }
    
    private func startPeriodicRefresh() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: refreshInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.refresh()
            }
        }
        
        // Do initial refresh
        Task {
            await refresh()
        }
    }
    
    private func stopPeriodicRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
}
