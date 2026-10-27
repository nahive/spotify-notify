import AppIntents

// Exposes playback to Shortcuts, Spotlight and Siri. The interactors are
// registered with `AppDependencyManager` in `NotifyApp.init`.

enum PlaybackIntentError: Error, CustomLocalizedStringResourceConvertible {
    case nothingPlaying
    case favoritesUnsupported

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .nothingPlaying: "Nothing is playing right now."
        case .favoritesUnsupported: "Only Apple Music supports favorites."
        }
    }
}

struct PlayPauseIntent: AppIntent {
    static let title: LocalizedStringResource = "Play or Pause"
    static let description = IntentDescription("Toggles playback in the music app Notify follows.")

    @Dependency private var musicInteractor: MusicInteractor

    @MainActor
    func perform() async throws -> some IntentResult {
        musicInteractor.playPause()
        return .result()
    }
}

struct NextTrackIntent: AppIntent {
    static let title: LocalizedStringResource = "Next Track"
    static let description = IntentDescription("Skips to the next track.")

    @Dependency private var musicInteractor: MusicInteractor

    @MainActor
    func perform() async throws -> some IntentResult {
        musicInteractor.nextTrack()
        return .result()
    }
}

struct PreviousTrackIntent: AppIntent {
    static let title: LocalizedStringResource = "Previous Track"
    static let description = IntentDescription("Goes back to the previous track.")

    @Dependency private var musicInteractor: MusicInteractor

    @MainActor
    func perform() async throws -> some IntentResult {
        musicInteractor.previousTrack()
        return .result()
    }
}

struct CurrentSongIntent: AppIntent {
    static let title: LocalizedStringResource = "Get Current Song"
    static let description = IntentDescription("Returns the song that is playing, as \"Title by Artist\".")

    @Dependency private var musicInteractor: MusicInteractor

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
        guard let track = musicInteractor.currentTrack else {
            throw PlaybackIntentError.nothingPlaying
        }
        let song = "\(track.name) by \(track.artist)"
        return .result(value: song, dialog: "\(song)")
    }
}

struct ShowNowPlayingIntent: AppIntent {
    static let title: LocalizedStringResource = "Show Now Playing Notification"
    static let description = IntentDescription("Shows the current song as a notification, like the keyboard shortcut.")

    @Dependency private var musicInteractor: MusicInteractor
    @Dependency private var notificationsInteractor: NotificationsInteractor

    @MainActor
    func perform() async throws -> some IntentResult {
        guard musicInteractor.currentTrack != nil else {
            throw PlaybackIntentError.nothingPlaying
        }
        notificationsInteractor.forceShowNotification()
        return .result()
    }
}

struct FavoriteCurrentSongIntent: AppIntent {
    static let title: LocalizedStringResource = "Favorite Current Song"
    static let description = IntentDescription("Marks the current Apple Music song as a favorite.")

    @Dependency private var musicInteractor: MusicInteractor

    @MainActor
    func perform() async throws -> some IntentResult {
        guard musicInteractor.supportsFavorites else {
            throw PlaybackIntentError.favoritesUnsupported
        }
        guard musicInteractor.currentTrack != nil else {
            throw PlaybackIntentError.nothingPlaying
        }
        musicInteractor.setFavorited(true)
        return .result()
    }
}

struct RecentSongsIntent: AppIntent {
    static let title: LocalizedStringResource = "Get Recent Songs"
    static let description = IntentDescription("Returns recently played songs from Notify's history, newest first.")

    @Parameter(title: "Count", default: 10, inclusiveRange: (1, 100))
    var count: Int

    @Dependency private var historyInteractor: HistoryInteractor

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<[String]> {
        let songs = historyInteractor.recentEntries(limit: count).map(\.displayTitle)
        return .result(value: songs)
    }
}

struct NotifyShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: CurrentSongIntent(),
            phrases: [
                "What's playing in \(.applicationName)",
                "Get the current song from \(.applicationName)",
            ],
            shortTitle: "Current Song",
            systemImageName: "music.note"
        )
        AppShortcut(
            intent: PlayPauseIntent(),
            phrases: ["Play or pause with \(.applicationName)"],
            shortTitle: "Play or Pause",
            systemImageName: "playpause.fill"
        )
        AppShortcut(
            intent: NextTrackIntent(),
            phrases: ["Skip the song with \(.applicationName)"],
            shortTitle: "Next Track",
            systemImageName: "forward.fill"
        )
        AppShortcut(
            intent: PreviousTrackIntent(),
            phrases: ["Previous song with \(.applicationName)"],
            shortTitle: "Previous Track",
            systemImageName: "backward.fill"
        )
        AppShortcut(
            intent: ShowNowPlayingIntent(),
            phrases: ["Show now playing in \(.applicationName)"],
            shortTitle: "Show Notification",
            systemImageName: "bell.badge"
        )
        AppShortcut(
            intent: FavoriteCurrentSongIntent(),
            phrases: ["Favorite this song with \(.applicationName)"],
            shortTitle: "Favorite Song",
            systemImageName: "star"
        )
        AppShortcut(
            intent: RecentSongsIntent(),
            phrases: ["Get recent songs from \(.applicationName)"],
            shortTitle: "Recent Songs",
            systemImageName: "clock"
        )
    }
}
