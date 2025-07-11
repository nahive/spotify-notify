import SwiftUI

// MARK: - SettingsView
struct SettingsView: View {
    @EnvironmentObject var defaultsInteractor: DefaultsInteractor
    @EnvironmentObject var musicInteractor: MusicInteractor
    @EnvironmentObject var notificationsInteractor: NotificationsInteractor
    
    var body: some View {
        TabView {
            GeneralSettingsView(defaultsInteractor: defaultsInteractor,
                                musicInteractor: musicInteractor,
                                notificationsInteractor: notificationsInteractor)
                .padding()
                .tabItem {
                    Label("General", systemImage: "gear")
                }
            
            NotificationSettingsView(defaultsInteractor: defaultsInteractor,
                                     notificationsInteractor: notificationsInteractor)
                .padding()
                .tabItem {
                    Label("Notifications", systemImage: "bell.badge")
                }
            
            AboutSettingsView()
                .padding()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .frame(maxWidth: 450)
        .tabViewStyle(.automatic)
    }
}

// MARK: - Preview
struct Settings_Preview: PreviewProvider {
    @StateObject private static var defaultsInteractor = DefaultsInteractor()
    
    static var previews: some View {
        SettingsView()
            .environmentObject(defaultsInteractor)
    }
}
