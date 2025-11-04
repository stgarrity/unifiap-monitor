import SwiftUI

@main
struct UniFiAPMonitorApp: App {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var wifiManager = WiFiManager()
    @State private var showingPreferences = false
    
    init() {
        print("UniFiAPMonitor app starting...")
    }
    
    var body: some Scene {
        MenuBarExtra("UniFi AP Monitor", systemImage: "wifi.circle.fill") {
            MenuBarView(showingPreferences: $showingPreferences)
                .environmentObject(locationManager)
                .environmentObject(wifiManager)
        }
        .menuBarExtraStyle(.menu)
        
        Window("Preferences", id: "preferences") {
            PreferencesView()
        }
        .windowResizability(.contentSize)
        .defaultPosition(.center)
    }
}
