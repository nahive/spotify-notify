import SwiftUI
import UserNotifications
import AppKit
import SwiftData

@main
struct NotifyApp: App {
    
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    @StateObject private var musicInteractor: MusicInteractor
    @StateObject private var defaultsInteractor: DefaultsInteractor
    @StateObject private var notificationsInteractor: NotificationsInteractor
    @StateObject private var historyInteractor: HistoryInteractor
    
    private let modelContainer: ModelContainer
    
    init() {
        do {
            modelContainer = try ModelContainer(for: SongHistory.self)
        } catch {
            fatalError("Failed to initialize ModelContainer: \(error)")
        }
        
        let historyInteractor = HistoryInteractor(modelContext: modelContainer.mainContext)
        let musicInteractor = MusicInteractor(historyInteractor: historyInteractor)
        let defaultsInteractor = DefaultsInteractor()
        let notificationsInteractor = NotificationsInteractor(defaultsInteractor: defaultsInteractor, musicInteractor: musicInteractor)
        
        self._musicInteractor = StateObject(wrappedValue: musicInteractor)
        self._defaultsInteractor = StateObject(wrappedValue: defaultsInteractor)
        self._notificationsInteractor = StateObject(wrappedValue: notificationsInteractor)
        self._historyInteractor = StateObject(wrappedValue: historyInteractor)
        
        musicInteractor.set(application: defaultsInteractor.selectedApplication)
    }
    
    var body: some Scene {
        MenuBarExtra {
            MenuView()
                .environmentObject(musicInteractor)
                .environmentObject(notificationsInteractor)
                .environmentObject(defaultsInteractor)
                .environmentObject(historyInteractor)
        } label: {
            MenuBarLabel()
                .environmentObject(musicInteractor)
                .environmentObject(defaultsInteractor)
        }
        .menuBarExtraStyle(.window)
        .modelContainer(modelContainer)
        
        Window("Song History", id: "history") {
            HistoryView()
                .environmentObject(historyInteractor)
                .environmentObject(musicInteractor)
        }
        .windowResizability(.contentSize)
        
        Settings {
            SettingsView()
                .environmentObject(musicInteractor)
                .environmentObject(notificationsInteractor)
                .environmentObject(defaultsInteractor)
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    @Environment(\.openSettings) var openSettings
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        System.log("Notify application started", level: .info)
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        guard !flag else {
            return true
        }
        // TODO: fix opening settings - maybe someday
        openSettings()
        return true
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}

private struct MenuBarLabel: View {
    @EnvironmentObject var musicInteractor: MusicInteractor
    @EnvironmentObject var defaultsInteractor: DefaultsInteractor
    
    var body: some View {
        HStack(spacing: 6) {
            if musicInteractor.currentTrack != nil || musicInteractor.isPlayingRadio {
                let isPlaying = musicInteractor.currentState == .playing
                Image(systemName: isPlaying ? "music.quarternote.3" : "music.note")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
            } else {
                Image(defaultsInteractor.isMenuIconColored ? "IconStatusBarColor" : "IconStatusBarMonochrome")
            }

            if defaultsInteractor.shouldShowSongInMenuBar {
                if let track = musicInteractor.currentTrack {
                    Text(track.name)
                        .font(.system(size: 13, weight: .medium))
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .frame(maxWidth: 180)
                } else if musicInteractor.isPlayingRadio {
                    Text("Radio")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}




