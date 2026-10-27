import SwiftUI

struct NotificationSettingsView: View {
    @Bindable var defaultsInteractor: DefaultsInteractor
    let shortcutsInteractor: ShortcutsInteractor

    var body: some View {
        Form {
            Section("Notifications") {
                Toggle("Enable notifications", isOn: $defaultsInteractor.areNotificationsEnabled)
                Group {
                    Toggle("Display notification on play | pause", isOn: $defaultsInteractor.shouldShowNotificationOnPlayPause)
                        .help("Also notify when you pause or resume, not just on track change.")
                    Toggle("Play notification sound", isOn: $defaultsInteractor.shouldPlayNotificationsSound)
                    Toggle("Disable notifications when player is focused", isOn: $defaultsInteractor.shouldDisableNotificationsOnFocus)
                        .help("Suppress banners while Spotify or Apple Music is the frontmost app.")
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
            // The shortcut only force-shows a notification, so it is dead while
            // notifications are off.
            .disabled(!defaultsInteractor.areNotificationsEnabled)
        }
        .formStyle(.grouped)
    }
}
