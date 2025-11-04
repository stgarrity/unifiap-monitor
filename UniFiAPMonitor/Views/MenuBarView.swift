import SwiftUI

struct MenuBarView: View {
    var body: some View {
        Text("UniFi AP Monitor")
        
        Divider()
        
        Text("Status: Initializing...")
        
        Divider()
        
        Button("Quit") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q")
    }
}
