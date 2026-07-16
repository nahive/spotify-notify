import AppKit
import Observation
import SwiftUI

/// Adapts MusicInteractor's published state into the `NowPlaying` snapshots the
/// notch UI consumes, and owns the notch window's lifecycle.
@MainActor
@Observable
final class NotchInteractor {
    private(set) var track: NowPlaying?

    @ObservationIgnored private let musicInteractor: MusicInteractor
    @ObservationIgnored private let defaultsInteractor: DefaultsInteractor

    @ObservationIgnored private var musicObservationTask: Task<Void, Never>?
    @ObservationIgnored private var defaultsObservationTask: Task<Void, Never>?
    @ObservationIgnored private var windowController: NotchWindowController?

    private static let cacheLimit = 64
    @ObservationIgnored private var artworkCache: [String: NSImage] = [:]
    @ObservationIgnored private var accentCache: [String: Color] = [:]
    @ObservationIgnored private var artworkLoadTask: Task<Void, Never>?

    init(musicInteractor: MusicInteractor, defaultsInteractor: DefaultsInteractor) {
        self.musicInteractor = musicInteractor
        self.defaultsInteractor = defaultsInteractor

        // Window creation is deferred past App.init automatically: the first
        // Observations emission arrives on a later run-loop pass, after AppKit
        // has finished launching.
        bind()
    }

    // MARK: - Controls (called by the notch pill)

    func togglePlayPause() {
        musicInteractor.playPause()
    }

    func nextTrack() {
        musicInteractor.nextTrack()
    }

    func previousTrack() {
        musicInteractor.previousTrack()
    }

    // MARK: - Bindings

    private func bind() {
        let musicInteractor = musicInteractor
        musicObservationTask = Task { [weak self] in
            for await (track, state) in Observations({ (musicInteractor.currentTrack, musicInteractor.currentState) }) {
                guard let self else { return }
                self.rebuild(from: track, isPlaying: state == .playing)
            }
        }

        // Unlike the old objectWillChange subscription this only fires for the
        // one setting the window lifecycle depends on, so no debounce is needed.
        let defaultsInteractor = defaultsInteractor
        defaultsObservationTask = Task { [weak self] in
            for await _ in Observations({ defaultsInteractor.notchVisibility }) {
                guard let self else { return }
                self.reconfigureNotchWindow()
            }
        }
    }

    private func rebuild(from musicTrack: MusicTrack?, isPlaying: Bool) {
        guard let musicTrack else {
            artworkLoadTask?.cancel()
            track = nil
            return
        }

        let artwork = resolvedArtwork(for: musicTrack)

        track = NowPlaying(
            title: musicTrack.name,
            artist: musicTrack.artist,
            album: musicTrack.album,
            isPlaying: isPlaying,
            artwork: artwork,
            accentColor: artwork.map { accentColor(for: musicTrack.id, image: $0) } ?? NowPlaying.fallbackAccent
        )
    }

    // MARK: - Artwork

    private func resolvedArtwork(for musicTrack: MusicTrack) -> NSImage? {
        switch musicTrack.artwork {
        case .image(let image):
            return image
        case .url(let url):
            if let cached = artworkCache[musicTrack.id] {
                return cached
            }
            loadArtwork(from: url, trackId: musicTrack.id)
            return nil
        case nil:
            return nil
        }
    }

    private func loadArtwork(from url: URL, trackId: String) {
        artworkLoadTask?.cancel()
        artworkLoadTask = Task { [weak self] in
            guard let (data, _) = try? await URLSession.shared.data(from: url),
                  !Task.isCancelled,
                  let image = NSImage(data: data),
                  let self else { return }

            if self.artworkCache.count > Self.cacheLimit {
                self.artworkCache.removeAll()
            }
            self.artworkCache[trackId] = image

            // Republish only if the loaded artwork still belongs to the current track.
            if self.musicInteractor.currentTrack?.id == trackId {
                self.rebuild(
                    from: self.musicInteractor.currentTrack,
                    isPlaying: self.musicInteractor.currentState == .playing
                )
            }
        }
    }

    private func accentColor(for trackId: String, image: NSImage) -> Color {
        if let cached = accentCache[trackId] {
            return cached
        }
        let color = ArtworkAccent.color(from: image) ?? NowPlaying.fallbackAccent
        if accentCache.count > Self.cacheLimit {
            accentCache.removeAll()
        }
        accentCache[trackId] = color
        return color
    }

    // MARK: - Window lifecycle

    private func reconfigureNotchWindow() {
        let enabled = defaultsInteractor.notchVisibility != .off
        if enabled, windowController == nil {
            let viewModel = NotchViewModel(notch: self, defaults: defaultsInteractor)
            windowController = NotchWindowController(viewModel: viewModel)
        } else if !enabled, let controller = windowController {
            controller.close()
            windowController = nil
        }
    }
}
