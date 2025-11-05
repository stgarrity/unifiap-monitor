import SwiftUI

@main
struct UniFiAPMonitorApp: App {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var wifiManager = WiFiManager()
    @StateObject private var appState = AppState()
    @State private var showingPreferences = false
    
    var body: some Scene {
        MenuBarExtra {
            MenuBarView(showingPreferences: $showingPreferences)
                .environmentObject(locationManager)
                .environmentObject(wifiManager)
                .environmentObject(appState)
                .onAppear {
                    // Pass managers to AppState
                    appState.locationManager = locationManager
                    appState.wifiManager = wifiManager
                }
        } label: {
            Image(systemName: appState.connectionState.icon)
        }
        .menuBarExtraStyle(.menu)
        
        Window("Preferences", id: "preferences") {
            PreferencesView()
                .environmentObject(appState)
        }
        .windowResizability(.contentSize)
        .defaultPosition(.center)
    }
}
