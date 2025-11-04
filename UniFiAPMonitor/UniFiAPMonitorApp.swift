import SwiftUI

@main
struct UniFiAPMonitorApp: App {
    init() {
        print("UniFiAPMonitor app starting...")
    }
    
    var body: some Scene {
        MenuBarExtra("UniFi AP Monitor", systemImage: "wifi.circle.fill") {
            MenuBarView()
        }
        .menuBarExtraStyle(.menu)
    }
}
