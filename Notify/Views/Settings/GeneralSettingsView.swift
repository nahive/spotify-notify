import SwiftUI

struct GeneralSettingsView: View {
    let defaultsInteractor: DefaultsInteractor
    let musicInteractor: MusicInteractor
    let notificationsInteractor: NotificationsInteractor

    var body: some View {
        Form {
            Section("Music app") {
                musicAppSelectionView
                    .frame(maxWidth: .infinity)
            }

            Section("Permissions") {
                notificationPermissionsView

                if let selectedApplication = defaultsInteractor.selectedApplication {
                    controlPermissionsView(for: selectedApplication)
                }
            }
        }
        .formStyle(.grouped)
        .onChange(of: defaultsInteractor.selectedApplication) { _, new in
            musicInteractor.set(application: new)
        }
        .task {
            // Each poll fires a live AppleEvent at the player (permission check),
            // so keep the cadence low while the tab is visible. `.task` cancels
            // the loop when the view disappears.
            refreshPermissions()
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(5))
                refreshPermissions()
            }
        }
    }

    private var musicAppSelectionView: some View {
        HStack {
            ForEach(SupportedMusicApplication.allCases, id: \.rawValue) { app in
                ZStack {
                    if app.isInstalled {
                        if let icon = app.icon {
                            Image(nsImage: icon)
                                .resizable()
                                .frame(width: 80, height: 80)
                        } else {
                            Text(app.appName)
                                .frame(width: 80, height: 80)
                        }
                    } else {
                        Text("\(app.appName) is not installed")
                            .frame(width: 80, height: 80)
                            .multilineTextAlignment(.center)
                    }
                }
                .background(defaultsInteractor.selectedApplication == app ? app.color.opacity(0.5) : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .onTapGesture {
                    guard app.isInstalled else { return }
                    defaultsInteractor.selectedApplication = app
                }
                .accessibilityLabel("Select \(app.appName)")
            }
        }
    }

    private var notificationPermissionsView: some View {
        HStack {
            Circle()
                .foregroundStyle(notificationsInteractor.areNotificationsEnabled ? Color.appAccent : Color.red)
                .frame(width: 8, height: 8)
            Text("Notification permissions")
            Spacer()
            if !notificationsInteractor.areNotificationsEnabled {
                Button("Enable notifications") {
                    notificationsInteractor.registerForNotifications()
                }
            }
        }
    }

    @ViewBuilder
    private func controlPermissionsView(for app: SupportedMusicApplication) -> some View {
        HStack {
            switch musicInteractor.permissionStatus {
            case .granted:
                Circle()
                    .foregroundStyle(Color.appAccent)
                    .frame(width: 8, height: 8)
                Text("Control permissions")
            case .closed:
                Circle()
                    .foregroundStyle(Color.yellow)
                    .frame(width: 8, height: 8)
                Text("Control permissions")
                Spacer()
                Button("Open \(app.appName) to enable automation") {
                    musicInteractor.openApplication()
                }
            case .denied:
                Circle()
                    .foregroundStyle(Color.red)
                    .frame(width: 8, height: 8)
                Text("Control permissions")
                Spacer()
                Button("Enable control for \(app.appName)") {
                    musicInteractor.registerForAutomation(for: app)
                }
            }
        }
    }

    private func refreshPermissions() {
        notificationsInteractor.updateNotificationsPermissions()
        musicInteractor.updateControlPermissions()
    }
}

extension SupportedMusicApplication {
    var color: Color {
        switch self {
        case .applemusic:
            .appleMusic
        case .spotify:
            .spotify
        }
    }
    
    var icon: NSImage? {
        getAppIcon(for: bundleId)
    }
    
    private func getAppIcon(for bundleIdentifier: String) -> NSImage? {
        guard let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) else {
            return nil
        }

        return NSWorkspace.shared.icon(forFile: appURL.path)
    }
}
