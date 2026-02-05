import SwiftUI
import LaunchAtLogin

struct NotificationSettingsView: View {
    @StateObject var defaultsInteractor: DefaultsInteractor
    let notificationsInteractor: NotificationsInteractor
    @State private var connectedMonitors: [MonitorInfo] = MonitorInfo.allConnected

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
                MonitorBlacklistSection(
                    defaultsInteractor: defaultsInteractor,
                    monitors: connectedMonitors
                )
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
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didChangeScreenParametersNotification)) { _ in
            connectedMonitors = MonitorInfo.allConnected
        }
    }
}

private struct MonitorBlacklistSection: View {
    @ObservedObject var defaultsInteractor: DefaultsInteractor
    let monitors: [MonitorInfo]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Divider()
                .padding(.vertical, 4)
            Text("Skip notifications when main display is:")
                .font(.subheadline)
                .foregroundColor(.secondary)
            ForEach(monitors) { monitor in
                Toggle(isOn: Binding(
                    get: { defaultsInteractor.isMonitorBlacklisted(monitor.id) },
                    set: { _ in defaultsInteractor.toggleMonitorBlacklist(monitor.id) }
                )) {
                    HStack {
                        Text(monitor.name)
                        if monitor.isMain {
                            Text("(current)")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                }
            }
            Text("Useful when using Dynamic Island apps on your built-in display")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}
