import SwiftUI
import LaunchAtLogin

struct NotificationSettingsView: View {
    @Bindable var defaultsInteractor: DefaultsInteractor
    let shortcutsInteractor: ShortcutsInteractor

    var body: some View {
        Form {
            Section {
                LaunchAtLogin.Toggle("Launch on startup")
                Toggle("Show song name in menu bar", isOn: $defaultsInteractor.shouldShowSongInMenuBar)
            }

            Section("Notifications") {
                Toggle("Enable notifications", isOn: $defaultsInteractor.areNotificationsEnabled)
                Group {
                    Toggle("Display notification on play | pause", isOn: $defaultsInteractor.shouldShowNotificationOnPlayPause)
                    Toggle("Play notification sound", isOn: $defaultsInteractor.shouldPlayNotificationsSound)
                    Toggle("Disable notifications when player is focused", isOn: $defaultsInteractor.shouldDisableNotificationsOnFocus)
                    Toggle("Include album art", isOn: $defaultsInteractor.shouldShowAlbumArt)
                    Toggle("Display song progress in notification", isOn: $defaultsInteractor.shouldShowSongProgress)
                }
                .disabled(!defaultsInteractor.areNotificationsEnabled)
            }

            Section("Shortcut") {
                LabeledContent("Display notification on") {
                    ShortcutView(shortcutsInteractor: shortcutsInteractor, defaultsInteractor: defaultsInteractor)
                        .frame(width: 160, height: 26)
                }
            }
        }
        .formStyle(.grouped)
    }
}
