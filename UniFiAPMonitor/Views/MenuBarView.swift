import SwiftUI
import CoreLocation

struct MenuBarView: View {
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var wifiManager: WiFiManager
    @Binding var showingPreferences: Bool
    @Environment(\.openWindow) private var openWindow
    
    var body: some View {
        Text("UniFi AP Monitor")
            .font(.headline)
        
        Divider()
        
        Group {
            if locationManager.authorizationStatus == .authorizedAlways {
                if let ssid = wifiManager.currentSSID {
                    Text("Network: \(ssid)")
                    if let bssid = wifiManager.currentBSSID {
                        Text("BSSID: \(bssid)")
                            .font(.caption)
                    }
                } else if let error = wifiManager.errorMessage {
                    Text(error)
                        .foregroundColor(.secondary)
                } else {
                    Text("Not connected to WiFi")
                        .foregroundColor(.secondary)
                }
            } else if locationManager.authorizationStatus == .denied {
                Text("Location permission denied")
                    .foregroundColor(.red)
                Text("Enable in System Settings")
                    .font(.caption)
            } else {
                Text("Location permission required")
                    .foregroundColor(.orange)
            }
        }
        
        Divider()
        
        Button("Request Permission") {
            locationManager.requestPermission()
        }
        .disabled(locationManager.authorizationStatus == .authorizedAlways ||
                 locationManager.authorizationStatus == .denied)
        
        Button("Refresh WiFi Info") {
            wifiManager.getCurrentWiFiInfo()
        }
        .disabled(locationManager.authorizationStatus != .authorizedAlways)
        
        Divider()
        
        Button("Preferences...") {
            openWindow(id: "preferences")
        }
        
        Divider()
        
        Button("Quit") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q")
    }
    
    var statusText: String {
        if locationManager.authorizationStatus == .authorizedAlways {
            return wifiManager.isConnected ? "Connected" : "Not Connected"
        } else {
            return "Permission Required"
        }
    }
}
