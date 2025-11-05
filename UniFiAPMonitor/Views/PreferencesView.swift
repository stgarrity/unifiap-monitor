import SwiftUI

struct PreferencesView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.scenePhase) var scenePhase
    @EnvironmentObject var appState: AppState
    @State private var controllerURL: String = ""
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var alertTitle = ""
    @State private var isTesting = false
    @State private var isUpdatingCache = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("UniFi Controller Settings")
                .font(.title2)
                .padding(.top)
            
            Form {
                Section {
                    TextField("Controller URL", text: $controllerURL)
                        .textFieldStyle(.roundedBorder)
                    Text("Example: https://192.168.1.1:8443")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section {
                    TextField("Username", text: $username)
                        .textFieldStyle(.roundedBorder)
                    
                    SecureField("Password", text: $password)
                        .textFieldStyle(.roundedBorder)
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Access Point Cache")
                            .font(.headline)
                        
                        let cacheInfo = appState.getCacheInfo()
                        if cacheInfo.count > 0 {
                            Text("\(cacheInfo.count) access points cached")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            if let lastUpdated = cacheInfo.lastUpdated {
                                Text("Last updated: \(lastUpdated.formatted(date: .abbreviated, time: .shortened))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        } else {
                            Text("No access points cached")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                        
                        Button {
                            updateAPCache()
                        } label: {
                            HStack {
                                if isUpdatingCache {
                                    ProgressView()
                                        .controlSize(.small)
                                        .padding(.trailing, 4)
                                }
                                Text(isUpdatingCache ? "Updating..." : "Update AP Cache")
                            }
                        }
                        .disabled(isUpdatingCache || controllerURL.isEmpty || username.isEmpty || password.isEmpty)
                    }
                    .padding(.vertical, 8)
                }
            }
            .formStyle(.grouped)
            
            HStack(spacing: 12) {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                
                Button("Clear") {
                    clearCredentials()
                }
                .foregroundColor(.red)
                
                Button("Test Connection") {
                    testConnection()
                }
                .disabled(isTesting || controllerURL.isEmpty || username.isEmpty || password.isEmpty)
                
                Button("Save") {
                    saveCredentials()
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding(.bottom)
        }
        .frame(width: 500, height: 480)
        .onAppear {
            loadCredentials()
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                loadCredentials()
            }
        }
        .alert(alertTitle, isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func loadCredentials() {
        let credentials = KeychainManager.shared.retrieveUniFiCredentials()
        controllerURL = credentials.url ?? ""
        username = credentials.username ?? ""
        password = credentials.password ?? ""
    }
    
    private func saveCredentials() {
        guard !controllerURL.isEmpty else {
            alertTitle = "Error"
            alertMessage = "Controller URL is required"
            showAlert = true
            return
        }
        
        guard !username.isEmpty else {
            alertTitle = "Error"
            alertMessage = "Username is required"
            showAlert = true
            return
        }
        
        guard !password.isEmpty else {
            alertTitle = "Error"
            alertMessage = "Password is required"
            showAlert = true
            return
        }
        
        do {
            try KeychainManager.shared.saveUniFiCredentials(
                url: controllerURL,
                username: username,
                password: password
            )
            alertTitle = "Success"
            alertMessage = "Credentials saved securely to Keychain"
            showAlert = true
        } catch {
            alertTitle = "Error"
            alertMessage = "Failed to save credentials: \(error.localizedDescription)"
            showAlert = true
        }
    }
    
    private func clearCredentials() {
        do {
            try KeychainManager.shared.deleteUniFiCredentials()
            controllerURL = ""
            username = ""
            password = ""
            alertTitle = "Success"
            alertMessage = "Credentials cleared"
            showAlert = true
        } catch {
            alertTitle = "Error"
            alertMessage = "Failed to clear credentials: \(error.localizedDescription)"
            showAlert = true
        }
    }
    
    private func testConnection() {
        guard !controllerURL.isEmpty, !username.isEmpty, !password.isEmpty else {
            return
        }
        
        isTesting = true
        
        Task {
            do {
                let accessPoints = try await UniFiAPIClient.shared.testConnection(
                    url: controllerURL,
                    username: username,
                    password: password
                )
                
                await MainActor.run {
                    isTesting = false
                    alertTitle = "Success"
                    alertMessage = "Connected successfully!\n\nFound \(accessPoints.count) access point(s):\n" +
                        accessPoints.map { "• \($0.displayName) (\($0.mac))" }.joined(separator: "\n")
                    showAlert = true
                }
            } catch {
                await MainActor.run {
                    isTesting = false
                    alertTitle = "Connection Failed"
                    alertMessage = error.localizedDescription
                    showAlert = true
                }
            }
        }
    }
    
    private func updateAPCache() {
        isUpdatingCache = true
        
        Task {
            do {
                try await appState.updateAPCache()
                
                await MainActor.run {
                    isUpdatingCache = false
                    let cacheInfo = appState.getCacheInfo()
                    alertTitle = "Cache Updated"
                    alertMessage = "Successfully cached \(cacheInfo.count) access point(s)"
                    showAlert = true
                }
            } catch {
                await MainActor.run {
                    isUpdatingCache = false
                    alertTitle = "Update Failed"
                    alertMessage = error.localizedDescription
                    showAlert = true
                }
            }
        }
    }
}
