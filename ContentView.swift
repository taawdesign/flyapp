import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "swift")
                .resizable()
                .frame(width: 80, height: 80)
                .foregroundColor(.orange)
            
            Text("Welcome to SwiftIDE")
                .font(.largeTitle)
                .bold()
            
            Text("Simulating real-time from GitHub Action")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Button(action: {
                print("Button tapped!")
            }) {
                Text("Get Started")
                    .bold()
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(15)
            }
        }
        .padding()
    }
}
