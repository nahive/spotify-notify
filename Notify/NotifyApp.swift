import SwiftUI
import UserNotifications
import AppKit
import SwiftData
import AppIntents

// MARK: - Main App
@main
struct NotifyApp: App {
    
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    @State private var musicInteractor: MusicInteractor
    @State private var defaultsInteractor: DefaultsInteractor
    @State private var notificationsInteractor: NotificationsInteractor
    @State private var historyInteractor: HistoryInteractor
    @State private var shortcutsInteractor: ShortcutsInteractor
    @State private var notchInteractor: NotchInteractor

    private let modelContainer: ModelContainer

    init() {
        modelContainer = Self.makeModelContainer()
        
        let historyInteractor = HistoryInteractor(modelContext: modelContainer.mainContext)
        let musicInteractor = MusicInteractor(historyInteractor: historyInteractor)
        let defaultsInteractor = DefaultsInteractor()
        let notificationsInteractor = NotificationsInteractor(defaultsInteractor: defaultsInteractor, musicInteractor: musicInteractor)
        let shortcutsInteractor = ShortcutsInteractor(defaultsInteractor: defaultsInteractor, notificationsInteractor: notificationsInteractor)
        let notchInteractor = NotchInteractor(musicInteractor: musicInteractor, defaultsInteractor: defaultsInteractor)

        self._musicInteractor = State(initialValue: musicInteractor)
        self._defaultsInteractor = State(initialValue: defaultsInteractor)
        self._notificationsInteractor = State(initialValue: notificationsInteractor)
        self._historyInteractor = State(initialValue: historyInteractor)
        self._shortcutsInteractor = State(initialValue: shortcutsInteractor)
        self._notchInteractor = State(initialValue: notchInteractor)

        AppDependencyManager.shared.add(dependency: musicInteractor)
        AppDependencyManager.shared.add(dependency: notificationsInteractor)
        AppDependencyManager.shared.add(dependency: historyInteractor)

        musicInteractor.set(selection: defaultsInteractor.playerSelection)
        shortcutsInteractor.registerSavedShortcutAfterLaunch()
    }

    /// Opens the history store, quarantining a corrupt one instead of crashing.
    private static func makeModelContainer() -> ModelContainer {
        let notifyURL = URL.applicationSupportDirectory.appendingPathComponent("Notify")
        try? FileManager.default.createDirectory(at: notifyURL, withIntermediateDirectories: true)

        let storeURL = notifyURL.appendingPathComponent("SongHistory.sqlite")
        let schema = Schema(versionedSchema: NotifySchemaV2.self)

        func openStore() throws -> ModelContainer {
            try ModelContainer(
                for: schema,
                migrationPlan: NotifyMigrationPlan.self,
                configurations: ModelConfiguration(url: storeURL)
            )
        }

        do {
            return try openStore()
        } catch {
            System.log("Failed to open history store, quarantining it: \(error)", level: .error)

            // Keep the user's data recoverable: move the store aside rather than
            // deleting it. The WAL/SHM sidecars must move too, or a stale WAL
            // would replay into the fresh store.
            let stamp = Date.now.formatted(.iso8601.year().month().day().dateSeparator(.dash))
            for suffix in ["", "-wal", "-shm"] {
                let source = notifyURL.appendingPathComponent("SongHistory.sqlite\(suffix)")
                let target = notifyURL.appendingPathComponent("SongHistory-corrupt-\(stamp).sqlite\(suffix)")
                try? FileManager.default.moveItem(at: source, to: target)
            }

            do {
                return try openStore()
            } catch {
                // Last resort: run this session in memory rather than crashing
                // a menu bar app at launch.
                System.log("Recreating history store failed, using in-memory store: \(error)", level: .error)
                do {
                    return try ModelContainer(
                        for: schema,
                        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
                    )
                } catch {
                    fatalError("Failed to create even an in-memory ModelContainer: \(error)")
                }
            }
        }
    }

    var body: some Scene {
        MenuBarExtra {
            MenuView()
                .environment(musicInteractor)
                .environment(notchInteractor)
                .environment(notificationsInteractor)
                .environment(defaultsInteractor)
                .environment(historyInteractor)
        } label: {
            MenuBarLabel()
                .environment(musicInteractor)
                .environment(defaultsInteractor)
        }
        .menuBarExtraStyle(.window)
        .modelContainer(modelContainer)

        Window("Song History", id: "history") {
            HistoryView()
                .environment(historyInteractor)
                .environment(musicInteractor)
        }
        .windowResizability(.contentMinSize)
        .windowToolbarStyle(.unifiedCompact)

        Settings {
            SettingsView()
                .environment(musicInteractor)
                .environment(notificationsInteractor)
                .environment(defaultsInteractor)
                .environment(shortcutsInteractor)
        }
        .windowToolbarStyle(.unifiedCompact)
    }
}

// MARK: - App Delegate
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        System.log("Notify application started", level: .info)
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        guard !flag else {
            return true
        }
        // `@Environment(\.openSettings)` only resolves inside a View, so the
        // AppKit responder-chain action is the only route from a delegate.
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        AppWindow.bringToFront(where: AppWindow.isSettings)
        return true
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}

// MARK: - AppWindow
/// Opens the app's windows in front. Notify is an LSUIElement agent and its
/// MenuBarExtra panel never activates the app, so a window opened from it
/// appears behind the frontmost app without focus. Activating first isn't
/// enough either: SwiftUI creates the window on a later run-loop pass, after
/// the panel has closed and focus has returned to the previous app.
@MainActor
enum AppWindow {
    static func showSettings(using openSettings: OpenSettingsAction) {
        openSettings()
        bringToFront(where: isSettings)
    }

    static func showHistory(using openWindow: OpenWindowAction) {
        openWindow(id: "history")
        bringToFront(where: isHistory)
    }

    static func isSettings(_ window: NSWindow) -> Bool {
        window.identifier?.rawValue == "com_apple_SwiftUI_Settings_window"
    }

    /// SwiftUI names `Window(id: "history")` instances "history-AppWindow-N".
    static func isHistory(_ window: NSWindow) -> Bool {
        window.identifier?.rawValue.hasPrefix("history") == true
    }

    static func bringToFront(where matches: @escaping @MainActor (NSWindow) -> Bool) {
        NSApp.activate()
        Task {
            // Poll briefly for the window SwiftUI is about to create.
            for _ in 0..<20 {
                if let window = NSApp.windows.first(where: { matches($0) && $0.isVisible }) {
                    NSApp.activate()
                    window.makeKeyAndOrderFront(nil)
                    window.orderFrontRegardless()
                    return
                }
                try? await Task.sleep(for: .milliseconds(25))
            }
        }
    }
}

// MARK: - MenuBarLabel
private struct MenuBarLabel: View {
    @Environment(MusicInteractor.self) private var musicInteractor
    @Environment(DefaultsInteractor.self) private var defaultsInteractor
    
    var body: some View {
        HStack(spacing: 6) {
            statusIcon
            
            if defaultsInteractor.shouldShowSongInMenuBar {
                statusText
            }
        }
        .contentTransition(.symbolEffect(.replace))
    }
    
    @ViewBuilder
    private var statusIcon: some View {
        if musicInteractor.currentTrack != nil || musicInteractor.isPlayingRadio {
            let isPlaying = musicInteractor.currentState == .playing
            Image(systemName: isPlaying ? "music.quarternote.3" : "music.note")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.primary)
                .symbolEffect(.bounce, value: isPlaying)
        } else {
            Image("IconStatusBarMonochrome")
        }
    }
    
    @ViewBuilder
    private var statusText: some View {
        if let track = musicInteractor.currentTrack {
            Text(track.name)
                .font(.system(size: 13, weight: .medium))
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: 180)
                .contentTransition(.interpolate)
        } else if musicInteractor.isPlayingRadio {
            Text("Radio")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)
                .contentTransition(.interpolate)
        }
    }
}
