import SwiftUI
import LaunchAtLogin

struct NotificationSettingsView: View {
    @StateObject var defaultsInteractor: DefaultsInteractor
    let notificationsInteractor: NotificationsInteractor
    
    var body: some View {
        VStack(alignment: .leading) {
            LaunchAtLogin.Toggle("Launch on startup")
            Toggle(isOn: defaultsInteractor.$shouldShowSongInMenuBar) {
                Text("Show song name in menu bar")
            }
            Divider()
                .padding()
            Toggle(isOn: defaultsInteractor.$areNotificationsEnabled) {
                Text("Enable notifications")
            }
            VStack(alignment: .leading) {
                Toggle(isOn: defaultsInteractor.$shouldShowNotificationOnPlayPause) {
                    Text("Display notification on play | pause")
                }
                Toggle(isOn: defaultsInteractor.$shouldPlayNotificationsSound) {
                    Text("Play notification sound")
                }
                Toggle(isOn: defaultsInteractor.$shouldDisableNotificationsOnFocus) {
                    Text("Disable notifications when player is focused")
                }
                Toggle(isOn: defaultsInteractor.$shouldShowAlbumArt) {
                    Text("Include album art")
                }
                Toggle(isOn: defaultsInteractor.$shouldShowSongProgress) {
                    Text("Display song progress in notification")
                }
            }
            .padding(.leading)
            .disabled(!defaultsInteractor.areNotificationsEnabled)
            Divider()
                .padding()
            HStack() {
                Text("Display notification on")
                ShortcutView(notificationsInteractor: notificationsInteractor, defaultsInteractor: defaultsInteractor)
                    .frame(height: 30)
            }
        }
        .padding()
    }
}
