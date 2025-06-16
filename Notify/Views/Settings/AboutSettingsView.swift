import SwiftUI

struct AboutSettingsView: View {
    private enum Const {
        static let homepage = "https://nahive.github.io".asURL!
        static let repo = "https://github.com/nahive/spotify-notify".asURL!
    }
    
    var body: some View {
        VStack {
            Image(.iconSettings)
                .resizable()
                .frame(width: 100, height: 100)
                .fixedSize()
                .padding()
            
            HStack {
                Button("Source") {
                    NSWorkspace.shared.open(Const.repo)
                }
                Button("Home") {
                    NSWorkspace.shared.open(Const.homepage)
                }
                Button("Quit") {
                    NSApp.terminate(nil)
                }
            }
            .padding()
            Text("Created with ❤ by nahive")
                .padding(.bottom)
                .foregroundStyle(Color.gray)
                .font(.system(size: 10))
        }
    }
}
