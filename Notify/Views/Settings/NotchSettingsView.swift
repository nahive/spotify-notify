import SwiftUI

struct NotchSettingsView: View {
    @Bindable var defaultsInteractor: DefaultsInteractor

    var body: some View {
        VStack(alignment: .leading) {
            Picker("Show around notch", selection: $defaultsInteractor.notchVisibility) {
                ForEach(NotchVisibilityMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }

            Picker("Screen", selection: $defaultsInteractor.notchPreferredScreen) {
                Text("Automatic").tag(DefaultsInteractor.automaticScreen)
                ForEach(NSScreen.screens, id: \.localizedName) { screen in
                    Text(screen.localizedName).tag(screen.localizedName)
                }
            }
            .disabled(defaultsInteractor.notchVisibility == .off)

            Text("Shows the current song around the notch. On displays without a notch, a floating pill appears top-center. Hover over it for playback controls.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.top, 8)
        }
        .padding()
    }
}
