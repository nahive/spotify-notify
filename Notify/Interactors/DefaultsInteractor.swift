import Foundation
import Observation
import Magnet

enum NotchVisibilityMode: String, CaseIterable, Identifiable {
    case off, always, whilePlaying, onHover

    var id: String { rawValue }

    var title: String {
        switch self {
        case .off: "Off"
        case .always: "Always"
        case .whilePlaying: "While Playing"
        case .onHover: "On Hover"
        }
    }
}

@MainActor
@Observable
final class DefaultsInteractor {
    enum Key {
        static let selectedApplication = "selected.application.key"

        static let notificationsEnabled = "notifications.enabled.key"
        static let notificationsPlayPause = "notifications.playpause.key"
        static let notificationsSound = "notifications.sound.key"
        static let notificationsDisableOnFocus = "notifications.focus.key"
        static let notificationsLength = "notifications.length.key"

        static let showAlbumArt = "showalbumart.key"
        static let showSongProgress = "songprogress.key"

        static let menuBarShowSong = "menubarshowsong.key"
        static let shortcutKeyCode = "shortcut.keycode.key"
        static let shortcutModifiers = "shortcut.modifiers.key"

        static let notchVisibility = "notch.visibility.key"
        static let notchScreen = "notch.screen.key"
    }

    static let automaticScreen = "auto"

    @ObservationIgnored private let store = UserDefaults.standard

    // This class is the sole writer of these keys, so plain stored properties
    // with a `didSet` write-through replace @AppStorage. Keys and encodings are
    // byte-identical to the @AppStorage versions (enums store their rawValue),
    // so existing users keep their settings.

    var selectedApplication: SupportedMusicApplication? {
        didSet { store.set(selectedApplication?.rawValue, forKey: Key.selectedApplication) }
    }

    var areNotificationsEnabled: Bool {
        didSet { store.set(areNotificationsEnabled, forKey: Key.notificationsEnabled) }
    }
    var shouldShowNotificationOnPlayPause: Bool {
        didSet { store.set(shouldShowNotificationOnPlayPause, forKey: Key.notificationsPlayPause) }
    }
    var shouldPlayNotificationsSound: Bool {
        didSet { store.set(shouldPlayNotificationsSound, forKey: Key.notificationsSound) }
    }
    var shouldDisableNotificationsOnFocus: Bool {
        didSet { store.set(shouldDisableNotificationsOnFocus, forKey: Key.notificationsDisableOnFocus) }
    }
    var notificationLength: Int {
        didSet { store.set(notificationLength, forKey: Key.notificationsLength) }
    }

    var shouldShowAlbumArt: Bool {
        didSet { store.set(shouldShowAlbumArt, forKey: Key.showAlbumArt) }
    }
    var shouldShowSongProgress: Bool {
        didSet { store.set(shouldShowSongProgress, forKey: Key.showSongProgress) }
    }

    var shouldShowSongInMenuBar: Bool {
        didSet { store.set(shouldShowSongInMenuBar, forKey: Key.menuBarShowSong) }
    }

    var notchVisibility: NotchVisibilityMode {
        didSet { store.set(notchVisibility.rawValue, forKey: Key.notchVisibility) }
    }
    var notchPreferredScreen: String {
        didSet { store.set(notchPreferredScreen, forKey: Key.notchScreen) }
    }

    private var shortcutKeyCode: Int {
        didSet { store.set(shortcutKeyCode, forKey: Key.shortcutKeyCode) }
    }
    private var shortcutModifier: Int {
        didSet { store.set(shortcutModifier, forKey: Key.shortcutModifiers) }
    }

    var shortcut: KeyCombo? {
        get {
            guard shortcutKeyCode != 0, shortcutModifier != 0 else { return nil }
            return KeyCombo(QWERTYKeyCode: shortcutKeyCode, carbonModifiers: shortcutModifier)
        }
        set {
            shortcutKeyCode = newValue?.QWERTYKeyCode ?? 0
            shortcutModifier = newValue?.modifiers ?? 0
        }
    }

    init() {
        let store = UserDefaults.standard
        // `object(forKey:) as? Bool ?? default` preserves @AppStorage's
        // absent-means-default semantics (`bool(forKey:)` would coerce to false).
        selectedApplication = store.string(forKey: Key.selectedApplication)
            .flatMap(SupportedMusicApplication.init(rawValue:))

        areNotificationsEnabled = store.object(forKey: Key.notificationsEnabled) as? Bool ?? true
        shouldShowNotificationOnPlayPause = store.object(forKey: Key.notificationsPlayPause) as? Bool ?? true
        shouldPlayNotificationsSound = store.object(forKey: Key.notificationsSound) as? Bool ?? false
        shouldDisableNotificationsOnFocus = store.object(forKey: Key.notificationsDisableOnFocus) as? Bool ?? true
        notificationLength = store.object(forKey: Key.notificationsLength) as? Int ?? 5

        shouldShowAlbumArt = store.object(forKey: Key.showAlbumArt) as? Bool ?? true
        shouldShowSongProgress = store.object(forKey: Key.showSongProgress) as? Bool ?? false

        shouldShowSongInMenuBar = store.object(forKey: Key.menuBarShowSong) as? Bool ?? true

        notchVisibility = store.string(forKey: Key.notchVisibility)
            .flatMap(NotchVisibilityMode.init(rawValue:)) ?? .off
        notchPreferredScreen = store.string(forKey: Key.notchScreen) ?? DefaultsInteractor.automaticScreen

        shortcutKeyCode = store.object(forKey: Key.shortcutKeyCode) as? Int ?? 0
        shortcutModifier = store.object(forKey: Key.shortcutModifiers) as? Int ?? 0
    }
}
