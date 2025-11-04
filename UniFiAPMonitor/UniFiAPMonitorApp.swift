import SwiftUI

@main
struct UniFiAPMonitorApp: App {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var wifiManager = WiFiManager()
    
    init() {
        print("UniFiAPMonitor app starting...")
    }
    
    var body: some Scene {
        MenuBarExtra("UniFi AP Monitor", systemImage: "wifi.circle.fill") {
            MenuBarView()
                .environmentObject(locationManager)
                .environmentObject(wifiManager)
        }
        .menuBarExtraStyle(.menu)
    }
}
