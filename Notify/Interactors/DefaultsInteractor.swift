import Foundation
import SwiftUI
import Magnet

@MainActor
final class DefaultsInteractor: ObservableObject {
    enum Key {
        static let selectedApplication = "selected.application.key"
        static let isFirstRun = "is.first.run.key"
        
        static let notificationsEnabled = "notifications.enabled.key"
        static let notificationsKeep = "notifications.keep.key"
        static let notificationsPlayPause = "notifications.playpause.key"
        static let notificationsSound = "notifications.sound.key"
        static let notificationsDisableOnFocus = "notifications.focus.key"
        static let notificationsLength = "notifications.length.key"
        
        static let showAlbumArt = "showalbumart.key"
        static let roundAlbumArt = "roundalbumart.key"
        static let showSongProgress = "songprogress.key"
        
        static let menuIconVisible = "menuiconvisible.key"
        static let menuIconColored = "menuiconcolored.key"
        static let menuBarShowSong = "menubarshowsong.key"
        static let shortcutKeyCode = "shortcut.keycode.key"
        static let shortcutModifiers = "shortcut.modifiers.key"
    }
    
    @AppStorage(Key.selectedApplication) var selectedApplication: SupportedMusicApplication?
    @AppStorage(Key.isFirstRun) var isFirstRun = true
    
    @AppStorage(Key.notificationsEnabled) var areNotificationsEnabled = true
    // deprecated - doesn't work reliably with modern macOS notification system
    // @AppStorage(Key.notificationsKeep) var shouldKeepNotificationsOnScreen = false
    @AppStorage(Key.notificationsPlayPause) var shouldShowNotificationOnPlayPause = true
    @AppStorage(Key.notificationsSound) var shouldPlayNotificationsSound = false
    @AppStorage(Key.notificationsDisableOnFocus) var shouldDisableNotificationsOnFocus = true
    @AppStorage(Key.notificationsLength) var notificationLength = 5
    
    @AppStorage(Key.showAlbumArt) var shouldShowAlbumArt = true
    
    // deprecated for now
    // @AppStorage(Key.roundAlbumArt) var shouldRoundAlbumArt = false
    @AppStorage(Key.showSongProgress) var shouldShowSongProgress = false
    
    // deprecated for now due to MenuBarExtra not respecting bindings properly
    // @AppStorage(Key.menuIconVisible) var isMenuIconVisible = true
    
    // deprecated - colored menu bar icon feature removed
    // @AppStorage(Key.menuIconColored) var isMenuIconColored = false
    @AppStorage(Key.menuBarShowSong) var shouldShowSongInMenuBar = true
    
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
