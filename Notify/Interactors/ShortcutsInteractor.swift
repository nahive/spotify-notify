import Foundation
import AppKit
import Observation
import Magnet

@MainActor
@Observable
final class ShortcutsInteractor {
    private static let hotKeyIdentifier = "showKey"

    private let defaultsInteractor: DefaultsInteractor
    private let notificationsInteractor: NotificationsInteractor
    @ObservationIgnored private var launchObserver: (any NSObjectProtocol)?

    init(defaultsInteractor: DefaultsInteractor, notificationsInteractor: NotificationsInteractor) {
        self.defaultsInteractor = defaultsInteractor
        self.notificationsInteractor = notificationsInteractor
    }

    /// Must not touch `HotKeyCenter` before launch finishes: its first use
    /// installs a Carbon handler on the event dispatcher, and doing that from
    /// `App.init` (which runs before `NSApplication` finishes launching) leaves
    /// the window-style MenuBarExtra panel receiving no mouse events at all.
    func registerSavedShortcutAfterLaunch() {
        launchObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didFinishLaunchingNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self else { return }
                if let launchObserver = self.launchObserver {
                    NotificationCenter.default.removeObserver(launchObserver)
                }
                self.launchObserver = nil
                self.registerSavedShortcut()
            }
        }
    }

    private func registerSavedShortcut() {
        guard let combo = defaultsInteractor.shortcut else { return }
        register(combo)
    }

    func update(keyCombo: KeyCombo?) {
        defaultsInteractor.shortcut = keyCombo

        HotKeyCenter.shared.unregisterHotKey(with: Self.hotKeyIdentifier)
        if let keyCombo {
            register(keyCombo)
        }
    }

    private func register(_ combo: KeyCombo) {
        let hotKey = HotKey(identifier: Self.hotKeyIdentifier, keyCombo: combo) { [weak self] _ in
            self?.notificationsInteractor.forceShowNotification()
        }
        HotKeyCenter.shared.register(with: hotKey)
    }
}
