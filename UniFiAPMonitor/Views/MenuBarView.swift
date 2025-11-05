import SwiftUI
import CoreLocation

struct MenuBarView: View {
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var wifiManager: WiFiManager
    @EnvironmentObject var appState: AppState
    @Binding var showingPreferences: Bool
    @Environment(\.openWindow) private var openWindow
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            Text("UniFi AP Monitor")
                .font(.headline)
                .padding(.horizontal)
                .padding(.top, 8)
            
            Divider()
                .padding(.vertical, 4)
            
            // Current Connection Status
            Group {
                if let ap = appState.currentAccessPoint {
                    // Connected to home AP
                    VStack(alignment: .leading, spacing: 4) {
                        Text(ap.displayName)
                            .font(.system(.body, design: .rounded, weight: .semibold))
                        
                        if let ssid = appState.currentSSID {
                            Label(ssid, systemImage: "wifi")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        if let bssid = appState.currentBSSID {
                            Text("BSSID: \(bssid)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        if ap.isOnline {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 6, height: 6)
                                Text("Online")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 6)
                    
                } else {
                    // Not connected to home or error state
                    VStack(alignment: .leading, spacing: 4) {
                        Text(appState.connectionState.displayText)
                            .font(.body)
                        
                        if let ssid = appState.currentSSID, appState.connectionState == .away {
                            Label(ssid, systemImage: "wifi")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            if let bssid = appState.currentBSSID {
                                Text("BSSID: \(bssid)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        if let error = appState.errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                                .lineLimit(2)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 6)
                }
            }
            
            // Last updated
            if let lastUpdated = appState.lastUpdated {
                Text("Updated \(timeAgo(lastUpdated))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                    .padding(.bottom, 6)
            }
            
            Divider()
            
            // Location permission request if needed
            if locationManager.authorizationStatus != .authorizedAlways {
                Button {
                    locationManager.requestPermission()
                } label: {
                    Label("Request Location Permission", systemImage: "location.circle")
                }
                .disabled(locationManager.authorizationStatus == .denied)
                
                if locationManager.authorizationStatus == .denied {
                    Text("Enable in System Settings → Privacy & Security → Location Services")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                        .padding(.vertical, 4)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Divider()
            }
            
            // Actions
            Button {
                Task {
                    await appState.forceRefresh()
                }
            } label: {
                Label("Refresh", systemImage: "arrow.clockwise")
            }
            .disabled(appState.isRefreshing)
            .keyboardShortcut("r")
            
            Divider()
            
            Button("Preferences...") {
                openWindow(id: "preferences")
            }
            .keyboardShortcut(",")
            
            Divider()
            
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }
        .frame(minWidth: 200)
    }
    
    private func timeAgo(_ date: Date) -> String {
        let seconds = Int(Date().timeIntervalSince(date))
        
        if seconds < 60 {
            return "just now"
        } else if seconds < 3600 {
            let minutes = seconds / 60
            return "\(minutes)m ago"
        } else {
            let hours = seconds / 3600
            return "\(hours)h ago"
        }
    }
}
