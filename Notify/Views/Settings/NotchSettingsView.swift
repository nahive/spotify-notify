import SwiftUI
import Combine

struct NotchSettingsView: View {
    @Bindable var defaultsInteractor: DefaultsInteractor

    /// Snapshot rather than reading `NSScreen.screens` in `body`, which never
    /// refreshes on hot-plug.
    @State private var screens = NSScreen.screens

    private var savedScreenIsConnected: Bool {
        let saved = defaultsInteractor.notchPreferredScreen
        return saved == DefaultsInteractor.automaticScreen
            || screens.contains { NotchGeometry.identifier(for: $0) == saved }
    }

    var body: some View {
        Form {
            Section {
                Picker("Show around notch", selection: $defaultsInteractor.notchVisibility) {
                    ForEach(NotchVisibilityMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }

                Picker("Screen", selection: $defaultsInteractor.notchPreferredScreen) {
                    Text("Automatic").tag(DefaultsInteractor.automaticScreen)
                    ForEach(screens, id: \.self) { screen in
                        Text(screen.localizedName).tag(NotchGeometry.identifier(for: screen))
                    }
                    if !savedScreenIsConnected {
                        Text("Disconnected display").tag(defaultsInteractor.notchPreferredScreen)
                    }
                }
                .disabled(defaultsInteractor.notchVisibility == .off)
            } footer: {
                Text("Shows the current song around the notch. On displays without a notch, a floating pill appears top-center. Hover over it for playback controls.")
            }
        }
        .formStyle(.grouped)
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didChangeScreenParametersNotification)) { _ in
            screens = NSScreen.screens
        }
    }
}
