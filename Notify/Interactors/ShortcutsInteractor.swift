import Foundation
import Observation
import Magnet

@MainActor
@Observable
final class ShortcutsInteractor {
    private static let hotKeyIdentifier = "showKey"

    private let defaultsInteractor: DefaultsInteractor
    private let notificationsInteractor: NotificationsInteractor

    init(defaultsInteractor: DefaultsInteractor, notificationsInteractor: NotificationsInteractor) {
        self.defaultsInteractor = defaultsInteractor
        self.notificationsInteractor = notificationsInteractor
    }

    func registerSavedShortcut() {
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
