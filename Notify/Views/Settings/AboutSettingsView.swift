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
            Text(versionString)
                .font(.footnote)
                .foregroundStyle(.secondary)
            Text("Created with ❤ by nahive")
                .padding(.bottom)
                // Fixed point sizes bypass the macOS "Larger Text" setting and
                // Color.gray on the window background fails 4.5:1.
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private var versionString: String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? "—"
        let build = info?["CFBundleVersion"] as? String ?? "—"
        return "Version \(short) (\(build))"
    }
}
