import SwiftUI
import WebKit

// MARK: - 1. APP ENTRY POINT
@main
struct SwiftIDEApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

// MARK: - 2. GITHUB SERVICE (The Deployment Engine)
class GitHubService: ObservableObject {
    @Published var statusMessage: String = "Ready"
    @Published var isDeploying: Bool = false
    
    // CONFIGURATION
    var owner: String = ""
    var repo: String = ""
    var token: String = ""
    
    func deploy(code: String) {
        guard !owner.isEmpty, !repo.isEmpty, !token.isEmpty else {
            statusMessage = "❌ Missing Repo Info or Token"
            return
        }
        
        self.isDeploying = true
        self.statusMessage = "🚀 Starting Deployment..."
        
        // 1. Create Package.swift (Fixed for Executable App)
        let packageContent = """
        // swift-tools-version: 5.9
        import PackageDescription
        
        let package = Package(
            name: "SwiftIDE",
            platforms: [.iOS(.v16)],
            products: [
                .executable(name: "SwiftIDE", targets: ["SwiftIDE"])
            ],
            targets: [
                .executableTarget(
                    name: "SwiftIDE",
                    path: ".",
                    sources: ["main.swift"]
                )
            ]
        )
        """
        
        // 2. Upload Package.swift
        uploadFile(path: "Package.swift", content: packageContent) { success in
            if success {
                // 3. Upload main.swift (Your Code)
                self.statusMessage = "Uploading Code..."
                self.uploadFile(path: "main.swift", content: code) { success in
                    if success {
                        // 4. Trigger the Stream Action
                        self.statusMessage = "Triggering Build..."
                        self.triggerWorkflow()
                    }
                }
            }
        }
    }
    
    // Helper: Uploads a file (Updates if exists, Creates if new)
    private func uploadFile(path: String, content: String, completion: @escaping (Bool) -> Void) {
        getFileSHA(path: path) { sha in
            let url = URL(string: "https://api.github.com/repos/\(self.owner)/\(self.repo)/contents/\(path)")!
            var request = URLRequest(url: url)
            request.httpMethod = "PUT"
            request.addValue("Bearer \(self.token)", forHTTPHeaderField: "Authorization")
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let body: [String: Any] = [
                "message": "Update \(path) from iPad",
                "content": Data(content.utf8).base64EncodedString(),
                "sha": sha ?? "" 
            ]
            
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                DispatchQueue.main.async {
                    if let http = response as? HTTPURLResponse, http.statusCode >= 200 && http.statusCode < 300 {
                        print("✅ Uploaded \(path)")
                        completion(true)
                    } else {
                        self.statusMessage = "❌ Upload Failed: \(path)"
                        if let data = data { print(String(data: data, encoding: .utf8) ?? "") }
                        self.isDeploying = false
                        completion(false)
                    }
                }
            }.resume()
        }
    }
    
    // Helper: Gets the SHA of a file so we can overwrite it
    private func getFileSHA(path: String, completion: @escaping (String?) -> Void) {
        let url = URL(string: "https://api.github.com/repos/\(owner)/\(repo)/contents/\(path)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, _, _ in
            if let data = data,
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let sha = json["sha"] as? String {
                completion(sha)
            } else {
                completion(nil)
            }
        }.resume()
    }
    
    // Helper: Triggers the GitHub Action
    private func triggerWorkflow() {
        let url = URL(string: "https://api.github.com/repos/\(owner)/\(repo)/actions/workflows/stream.yml/dispatches")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["ref": "main"]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { _, response, _ in
            DispatchQueue.main.async {
                self.isDeploying = false
                if let http = response as? HTTPURLResponse, http.statusCode == 204 {
                    self.statusMessage = "✅ Build Started! Check GitHub."
                } else {
                    self.statusMessage = "❌ Failed to Trigger Action"
                }
            }
        }.resume()
    }
}

// MARK: - 3. MAIN UI (With Trash Can Button)
struct ContentView: View {
    @StateObject private var gitService = GitHubService()
    
    // User Settings
    @AppStorage("gh_owner") private var ghOwner = ""
    @AppStorage("gh_repo") private var ghRepo = ""
    @AppStorage("gh_token") private var ghToken = ""
    @AppStorage("appetize_key") private var appetizeKey = ""

    @State private var codeText: String = "" 
    @State private var selectedTab = 0 
    
    var body: some View {
        NavigationSplitView {
            Form {
                Section(header: Text("GITHUB CONFIG")) {
                    TextField("Username (Owner)", text: $ghOwner)
                    TextField("Repo Name", text: $ghRepo)
                    SecureField("Access Token", text: $ghToken)
                }
                
                Section(header: Text("CLOUD STREAM")) {
                    TextField("Appetize Public Key", text: $appetizeKey)
                }
                
                Section {
                    Button(action: deployCode) {
                        if gitService.isDeploying {
                            ProgressView()
                        } else {
                            Text("Push & Build 🚀")
                                .bold()
                                .frame(maxWidth: .infinity)
                                .foregroundColor(.blue)
                        }
                    }
                    Text(gitService.statusMessage)
                        .font(.caption)
                        .foregroundColor(gitService.statusMessage.contains("✅") ? .green : .red)
                }
            }
            .navigationTitle("SwiftIDE")
        } detail: {
            VStack(spacing: 0) {
                // TOOLBAR
                HStack {
                    Picker("View", selection: $selectedTab) {
                        Text("Editor").tag(0)
                        Text("Cloud Simulator").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 250)
                    
                    Spacer()
                    
                    // --- NEW: CLEAR BUTTON ---
                    if selectedTab == 0 {
                        Button(action: { codeText = "" }) {
                            HStack {
                                Image(systemName: "trash")
                                Text("Clear")
                            }
                            .font(.caption).bold()
                            .foregroundColor(.white)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 12)
                            .background(Color.red)
                            .cornerRadius(8)
                        }
                    }
                    // -------------------------
                }
                .padding()
                .background(Color(white: 0.1))
                
                if selectedTab == 0 {
                    ZStack(alignment: .topLeading) {
                        if codeText.isEmpty {
                            Text("Tap 'Clear' above, then paste your code here...")
                                .foregroundColor(.gray)
                                .padding(12)
                        }
                        
                        TextEditor(text: $codeText)
                            .font(.custom("Menlo", size: 14))
                            .scrollContentBackground(.hidden)
                            .background(Color(white: 0.15))
                            .foregroundColor(.white)
                            .opacity(codeText.isEmpty ? 0.5 : 1)
                    }
                } else {
                    if appetizeKey.isEmpty {
                        Text("Enter Appetize Key in Sidebar after Build finishes")
                            .foregroundColor(.gray)
                    } else {
                        RemoteSimulatorView(publicKey: appetizeKey)
                    }
                }
            }
        }
        .onAppear {
            gitService.owner = ghOwner
            gitService.repo = ghRepo
            gitService.token = ghToken
        }
        .onChange(of: ghOwner) { gitService.owner = $0 }
        .onChange(of: ghRepo) { gitService.repo = $0 }
        .onChange(of: ghToken) { gitService.token = $0 }
    }
    
    func deployCode() {
        gitService.owner = ghOwner
        gitService.repo = ghRepo
        gitService.token = ghToken
        gitService.deploy(code: codeText)
    }
}

// MARK: - 4. STREAM VIEWER
struct RemoteSimulatorView: UIViewRepresentable {
    let publicKey: String
    func makeUIView(context: Context) -> WKWebView {
        let w = WKWebView(); w.scrollView.isScrollEnabled = false; return w
    }
    func updateUIView(_ uiView: WKWebView, context: Context) {
        if let url = URL(string: "https://appetize.io/embed/\(publicKey)?device=iphone16&autoplay=true&orientation=portrait") {
            uiView.load(URLRequest(url: url))
        }
    }
}
