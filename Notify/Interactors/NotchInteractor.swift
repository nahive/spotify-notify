import AppKit
import Combine
import SwiftUI

/// Adapts MusicInteractor's published state into the `NowPlaying` snapshots the
/// notch UI consumes, and owns the notch window's lifecycle. The window itself
/// only exists on macOS 26+; this class is cheap and safe on the 14.0 floor.
@MainActor
final class NotchInteractor: ObservableObject {
    @Published private(set) var track: NowPlaying?

    private let musicInteractor: MusicInteractor
    private let defaultsInteractor: DefaultsInteractor

    private var cancellables = Set<AnyCancellable>()
    // NotchWindowController is macOS 26-only, so it is held type-erased here.
    private var windowController: Any?

    private static let cacheLimit = 64
    private var artworkCache: [String: NSImage] = [:]
    private var accentCache: [String: Color] = [:]
    private var artworkLoadTask: Task<Void, Never>?

    init(musicInteractor: MusicInteractor, defaultsInteractor: DefaultsInteractor) {
        self.musicInteractor = musicInteractor
        self.defaultsInteractor = defaultsInteractor

        bind()

        // Defer window creation until AppKit has finished launching; a MainActor
        // task enqueued from App.init runs on the first run-loop pass after startup.
        Task { @MainActor [weak self] in
            self?.reconfigureNotchWindow()
        }
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

    func seek(to seconds: TimeInterval) {
        guard let duration = track?.duration, duration > 0 else { return }
        musicInteractor.seek(to: seconds / duration)
    }

    // MARK: - Bindings

    private func bind() {
        Publishers.CombineLatest(musicInteractor.$currentTrack, musicInteractor.$currentState)
            .removeDuplicates { $0.0 == $1.0 && $0.1 == $1.1 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] track, state in
                self?.rebuild(from: track, isPlaying: state == .playing)
            }
            .store(in: &cancellables)

        defaultsInteractor.objectWillChange
            .debounce(for: .milliseconds(100), scheduler: DispatchQueue.main)
            .sink { [weak self] in
                self?.reconfigureNotchWindow()
            }
            .store(in: &cancellables)
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
            duration: musicTrack.duration.map(TimeInterval.init),
            elapsedBase: musicInteractor.currentPositionSeconds,
            elapsedCapturedAt: .now,
            artwork: artwork,
            accentColor: artwork.map { accentColor(for: musicTrack.id, image: $0) } ?? NowPlaying.fallbackAccent,
            bundleIdentifier: musicInteractor.currentApplication?.bundleId
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
        guard #available(macOS 26.0, *) else { return }

        let enabled = defaultsInteractor.notchVisibility != .off
        if enabled, windowController == nil {
            let viewModel = NotchViewModel(notch: self, defaults: defaultsInteractor)
            windowController = NotchWindowController(viewModel: viewModel)
        } else if !enabled, let controller = windowController as? NotchWindowController {
            controller.close()
            windowController = nil
        }
    }
}
