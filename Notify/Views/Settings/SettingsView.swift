import SwiftUI

// MARK: - SettingsView
struct SettingsView: View {
    @Environment(DefaultsInteractor.self) var defaultsInteractor
    @Environment(MusicInteractor.self) var musicInteractor
    @Environment(NotificationsInteractor.self) var notificationsInteractor
    @Environment(ShortcutsInteractor.self) var shortcutsInteractor

    var body: some View {
        TabView {
            GeneralSettingsView(defaultsInteractor: defaultsInteractor,
                                musicInteractor: musicInteractor,
                                notificationsInteractor: notificationsInteractor)
                .tabItem {
                    Label("General", systemImage: "gear")
                }

            NotificationSettingsView(defaultsInteractor: defaultsInteractor,
                                     shortcutsInteractor: shortcutsInteractor)
                .tabItem {
                    Label("Notifications", systemImage: "bell.badge")
                }

            NotchSettingsView(defaultsInteractor: defaultsInteractor)
                .tabItem {
                    Label("Notch", systemImage: "sparkles.tv")
                }

            AboutSettingsView()
                .padding()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .frame(width: 450)
        .tabViewStyle(.automatic)
    }
}

