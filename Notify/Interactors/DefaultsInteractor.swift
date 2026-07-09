import Foundation
import SwiftUI
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
final class DefaultsInteractor: ObservableObject {
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

    @AppStorage(Key.selectedApplication) var selectedApplication: SupportedMusicApplication?

    @AppStorage(Key.notificationsEnabled) var areNotificationsEnabled = true
    @AppStorage(Key.notificationsPlayPause) var shouldShowNotificationOnPlayPause = true
    @AppStorage(Key.notificationsSound) var shouldPlayNotificationsSound = false
    @AppStorage(Key.notificationsDisableOnFocus) var shouldDisableNotificationsOnFocus = true
    @AppStorage(Key.notificationsLength) var notificationLength = 5

    @AppStorage(Key.showAlbumArt) var shouldShowAlbumArt = true
    @AppStorage(Key.showSongProgress) var shouldShowSongProgress = false

    @AppStorage(Key.menuBarShowSong) var shouldShowSongInMenuBar = true

    // The notch overlay is only available on macOS 26+, but the setting itself
    // must compile and persist on the macOS 14 floor.
    @AppStorage(Key.notchVisibility) var notchVisibility: NotchVisibilityMode = .off
    @AppStorage(Key.notchScreen) var notchPreferredScreen = DefaultsInteractor.automaticScreen

    @AppStorage(Key.shortcutKeyCode) private var shortcutKeyCode = 0
    @AppStorage(Key.shortcutModifiers) private var shortcutModifier = 0
    
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
}
