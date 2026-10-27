import SwiftUI
import LaunchAtLogin

struct GeneralSettingsView: View {
    @Bindable var defaultsInteractor: DefaultsInteractor
    let musicInteractor: MusicInteractor
    let notificationsInteractor: NotificationsInteractor

    var body: some View {
        Form {
            Section {
                LaunchAtLogin.Toggle("Launch on startup")
                Toggle("Show song name in menu bar", isOn: $defaultsInteractor.shouldShowSongInMenuBar)
            }

            Section {
                musicAppSelectionView
                    .frame(maxWidth: .infinity)
            } header: {
                Text("Music app")
            } footer: {
                if defaultsInteractor.playerSelection == .automatic {
                    Text(automaticFooter)
                }
            }

            Section("Permissions") {
                notificationPermissionsView

                if let application = musicInteractor.currentApplication {
                    controlPermissionsView(for: application)
                }
            }
        }
        .formStyle(.grouped)
        .onChange(of: defaultsInteractor.playerSelection) { _, new in
            musicInteractor.set(selection: new)
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

    private var automaticFooter: String {
        guard let application = musicInteractor.currentApplication else {
            return "Follows whichever of Spotify or Apple Music starts playing."
        }
        return "Follows whichever app starts playing. Currently following \(application.appName)."
    }

    private var musicAppSelectionView: some View {
        HStack(spacing: 12) {
            selectionTile(
                .automatic,
                title: "Automatic",
                color: .appAccent,
                isEnabled: true,
                help: "Follow whichever app is playing"
            ) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 30, weight: .medium))
                    .foregroundStyle(.primary)
                    .frame(width: 64, height: 64)
            }

            ForEach(SupportedMusicApplication.allCases, id: \.rawValue) { app in
                selectionTile(
                    .fixed(app),
                    title: app.appName,
                    color: app.color,
                    isEnabled: app.isInstalled,
                    help: app.isInstalled ? "Always use \(app.appName)" : "\(app.appName) is not installed"
                ) {
                    if let icon = app.icon {
                        Image(nsImage: icon)
                            .resizable()
                            .frame(width: 64, height: 64)
                    } else {
                        Image(systemName: "music.note")
                            .font(.system(size: 30))
                            .frame(width: 64, height: 64)
                    }
                }
            }
        }
    }

    private func selectionTile(
        _ selection: PlayerSelection,
        title: String,
        color: Color,
        isEnabled: Bool,
        help: String,
        @ViewBuilder icon: () -> some View
    ) -> some View {
        let isSelected = defaultsInteractor.playerSelection == selection
        return Button {
            defaultsInteractor.playerSelection = selection
        } label: {
            VStack(spacing: 6) {
                icon()
                Text(title)
                    .font(.caption)
                    .foregroundStyle(isSelected ? .primary : .secondary)
            }
            .padding(8)
            .frame(width: 96)
            .opacity(isEnabled ? 1 : 0.35)
            .background(isSelected ? color.opacity(0.35) : Color.clear,
                        in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .help(help)
        .accessibilityLabel(title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
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
