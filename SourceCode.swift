import SwiftUI

@main
struct TestApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 100))
                .foregroundColor(.green)
            
            Text("It Works!")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Your Cloud Compiler is successfully building apps.")
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
                .padding()
        }
    }
}
