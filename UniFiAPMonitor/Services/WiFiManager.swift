import Foundation
import CoreWLAN

class WiFiManager: ObservableObject {
    @Published var currentSSID: String?
    @Published var currentBSSID: String?
    @Published var isConnected: Bool = false
    @Published var errorMessage: String?
    
    func getCurrentWiFiInfo() {
        let client = CWWiFiClient.shared()
        guard let interface = client.interface() else {
            errorMessage = "Unable to access WiFi interface"
            isConnected = false
            return
        }
        
        currentSSID = interface.ssid()
        currentBSSID = interface.bssid()
        isConnected = currentSSID != nil
        
        if let ssid = currentSSID, let bssid = currentBSSID {
            print("Connected to: \(ssid)")
            print("BSSID: \(bssid)")
            errorMessage = nil
        } else {
            print("Not connected to WiFi")
            errorMessage = "Not connected to WiFi"
        }
    }
    
    func normalizedBSSID(_ bssid: String?) -> String? {
        guard let bssid = bssid else { return nil }
        return bssid.replacingOccurrences(of: ":", with: "").lowercased()
    }
}
