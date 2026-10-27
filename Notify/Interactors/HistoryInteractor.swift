import Foundation
import Observation
import SwiftData
import AppKit

struct HistoryStats: Equatable, Sendable {
    struct DayCount: Equatable, Sendable, Identifiable {
        let day: Date
        let plays: Int
        var id: Date { day }
    }

    struct NamedCount: Equatable, Sendable, Identifiable {
        let name: String
        let plays: Int
        var id: String { name }
    }

    var totalSongs = 0
    var uniqueArtists = 0
    var totalDuration = 0
    /// One entry per day for the last `HistoryInteractor.chartDays` days,
    /// zero-filled so the chart has no gaps.
    var playsPerDay: [DayCount] = []
    var topArtists: [NamedCount] = []
    var topAlbums: [NamedCount] = []

    static let empty = HistoryStats()
}

@MainActor
@Observable
final class HistoryInteractor {
    /// A track re-entering within this window is the same play, not a repeat.
    private static let repeatWindow: TimeInterval = 30
    /// Rows beyond this are dropped oldest-first; an always-running agent must
    /// not grow its store without bound.
    private static let historyLimit = 5_000
    private static let pageSize = 100
    static let chartDays = 14
    private static let topCount = 5

    @ObservationIgnored private let modelContext: ModelContext
    @ObservationIgnored private var saveTask: Task<Void, Never>?
    @ObservationIgnored private let imageCache = NSCache<NSUUID, NSImage>()

    /// The rows the history list shows: newest first, filtered by `query`,
    /// paged in `pageSize` steps by `loadMore()`.
    private(set) var entries: [SongHistory] = []
    private(set) var hasMore = false
    /// Bumped on every insert/delete so views can refresh derived data
    /// (stats, charts) without re-running it when only paging changed.
    private(set) var revision = 0

    /// Searched in the store, not in `entries`, so it reaches every row rather
    /// than only the loaded page.
    var query = "" {
        didSet {
            guard query != oldValue else { return }
            fetchLimit = Self.pageSize
            reload()
        }
    }

    @ObservationIgnored private var fetchLimit = HistoryInteractor.pageSize

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        imageCache.countLimit = 100
        reload()
    }

    func saveSongIfNeeded(from track: MusicTrack, musicApp: SupportedMusicApplication) {
        if let last = latestEntry(),
           last.trackId == track.id,
           Date.now.timeIntervalSince(last.playedAt) < Self.repeatWindow {
            return
        }

        // Chained so two saves can never straddle the artwork download and
        // insert duplicate rows.
        let previous = saveTask
        saveTask = Task { [weak self] in
            await previous?.value
            guard let self else { return }
            await self.saveSong(from: track, musicApp: musicApp)
        }
    }
    
    func saveSong(from track: MusicTrack, musicApp: SupportedMusicApplication) async {
        do {
            let albumArtwork = await getOrCreateAlbumArtwork(for: track)
            
            let historyEntry = SongHistory(
                trackId: track.id,
                trackName: track.name,
                artist: track.artist,
                album: track.album,
                albumArtist: track.albumArtist,
                duration: track.duration,
                playedAt: Date(),
                musicApp: musicApp.appName,
                artwork: albumArtwork,
                genre: track.genre,
                year: track.year,
                trackNumber: track.trackNumber,
                discNumber: track.discNumber,
                playedCount: track.playedCount,
                rating: track.rating,
                bpm: track.bpm,
                bitRate: track.bitRate,
                isLoved: track.isLoved,
                isStarred: track.isStarred,
                composer: track.composer,
                spotifyUrl: track.spotifyUrl,
                releaseDate: track.releaseDate
            )
            
            modelContext.insert(historyEntry)
            try modelContext.save()
            
            pruneHistory()
            didChange()
            System.log("Saved song to history: \(track.name) by \(track.artist)", level: .info)
            
        } catch {
            System.log("Failed to save song history: \(error)", level: .error)
        }
    }
    
    func getPlayCounts(for entry: SongHistory) -> (songPlays: Int, artistPlays: Int, albumPlays: Int) {
        // #Predicate can't traverse the model instance, so capture plain values.
        let trackName = entry.trackName
        let artist = entry.artist
        let album = entry.album

        do {
            let songPlays = try modelContext.fetchCount(FetchDescriptor<SongHistory>(
                predicate: #Predicate { $0.trackName == trackName && $0.artist == artist }
            ))

            let artistPlays = try modelContext.fetchCount(FetchDescriptor<SongHistory>(
                predicate: #Predicate { $0.artist == artist }
            ))

            let albumPlays = try modelContext.fetchCount(FetchDescriptor<SongHistory>(
                predicate: #Predicate { $0.album == album && $0.artist == artist }
            ))

            return (songPlays, artistPlays, albumPlays)
        } catch {
            System.log("Failed to get play counts: \(error)", level: .error)
            return (0, 0, 0)
        }
    }
    
    private func downloadArtworkData(from url: URL) async -> Data? {
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            return data
        } catch {
            System.log("Failed to download artwork from \(url): \(error)", level: .warning)
            return nil
        }
    }
    
    func loadMore() {
        guard hasMore else { return }
        fetchLimit += Self.pageSize
        reload()
    }

    private func reload() {
        let query = query.trimmingCharacters(in: .whitespacesAndNewlines)
        var descriptor = FetchDescriptor<SongHistory>(
            predicate: query.isEmpty ? nil : #Predicate {
                $0.trackName.localizedStandardContains(query)
                    || $0.artist.localizedStandardContains(query)
                    || ($0.album ?? "").localizedStandardContains(query)
            },
            sortBy: [SortDescriptor(\.playedAt, order: .reverse)]
        )
        // One extra row tells us whether another page exists without a count query.
        descriptor.fetchLimit = fetchLimit + 1

        do {
            let fetched = try modelContext.fetch(descriptor)
            hasMore = fetched.count > fetchLimit
            entries = Array(fetched.prefix(fetchLimit))
        } catch {
            System.log("Failed to load song history: \(error)", level: .error)
            entries = []
            hasMore = false
        }
    }

    private func didChange() {
        revision += 1
        reload()
    }

    private func latestEntry() -> SongHistory? {
        recentEntries(limit: 1).first
    }

    /// Newest rows regardless of the list's search and paging.
    func recentEntries(limit: Int) -> [SongHistory] {
        var descriptor = FetchDescriptor<SongHistory>(sortBy: [SortDescriptor(\.playedAt, order: .reverse)])
        descriptor.fetchLimit = limit
        return (try? modelContext.fetch(descriptor)) ?? []
    }
    
    func deleteHistoryEntry(_ entry: SongHistory) {
        // Captured before the delete: afterwards the relationship is gone and
        // the externalStorage blob would be orphaned forever.
        let artwork = entry.artwork
        modelContext.delete(entry)

        do {
            try modelContext.save()
            if let artwork {
                try deleteOrphanedArtwork([artwork])
            }
            didChange()
        } catch {
            System.log("Failed to delete history entry: \(error)", level: .error)
        }
    }

    func clearAllHistory() {
        do {
            try modelContext.delete(model: SongHistory.self)
            try modelContext.delete(model: AlbumArtwork.self)
            try modelContext.save()
            imageCache.removeAllObjects()

            didChange()
            System.log("Cleared all song history", level: .info)
        } catch {
            System.log("Failed to clear history: \(error)", level: .error)
        }
    }

    private func pruneHistory() {
        do {
            var descriptor = FetchDescriptor<SongHistory>(
                sortBy: [SortDescriptor(\.playedAt, order: .reverse)]
            )
            descriptor.fetchOffset = Self.historyLimit

            let stale = try modelContext.fetch(descriptor)
            guard !stale.isEmpty else { return }

            let artworks = Set(stale.compactMap(\.artwork))
            for entry in stale {
                modelContext.delete(entry)
            }
            try modelContext.save()
            try deleteOrphanedArtwork(artworks)

            System.log("Pruned \(stale.count) history rows", level: .info)
        } catch {
            System.log("Failed to prune history: \(error)", level: .error)
        }
    }

    /// Must run after the song deletes are saved: the inverse `songs`
    /// relationship only drops deleted rows once the delete is processed, so
    /// checking earlier sees the artwork as still in use and leaks its blob.
    private func deleteOrphanedArtwork(_ artworks: Set<AlbumArtwork>) throws {
        let orphaned = artworks.filter(\.songs.isEmpty)
        guard !orphaned.isEmpty else { return }

        for artwork in orphaned {
            imageCache.removeObject(forKey: artwork.id as NSUUID)
            modelContext.delete(artwork)
        }
        try modelContext.save()
    }

    func getHistoryStats() -> HistoryStats {
        // One pass over at most `historyLimit` rows, fetching only the columns
        // the stats use; skip materializing artwork and the rest of the row.
        var descriptor = FetchDescriptor<SongHistory>()
        descriptor.propertiesToFetch = [\.artist, \.album, \.duration, \.playedAt]

        do {
            let allHistory = try modelContext.fetch(descriptor)
            return HistoryStats(
                totalSongs: allHistory.count,
                uniqueArtists: Set(allHistory.map(\.artist)).count,
                totalDuration: allHistory.compactMap(\.duration).reduce(0, +),
                playsPerDay: Self.playsPerDay(allHistory),
                topArtists: Self.top(allHistory.map(\.artist)),
                topAlbums: Self.top(allHistory.compactMap { entry in
                    entry.album.map { "\($0) — \(entry.artist)" }
                })
            )
        } catch {
            System.log("Failed to get history stats: \(error)", level: .error)
            return .empty
        }
    }
    
    private static func playsPerDay(_ history: [SongHistory]) -> [HistoryStats.DayCount] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        guard let start = calendar.date(byAdding: .day, value: -(chartDays - 1), to: today) else { return [] }

        let counts = Dictionary(grouping: history.lazy.map(\.playedAt).filter { $0 >= start }) {
            calendar.startOfDay(for: $0)
        }.mapValues(\.count)

        return (0..<chartDays).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: start).map {
                HistoryStats.DayCount(day: $0, plays: counts[$0] ?? 0)
            }
        }
    }

    private static func top(_ names: [String]) -> [HistoryStats.NamedCount] {
        Dictionary(names.map { ($0, 1) }, uniquingKeysWith: +)
            .sorted { $0.value != $1.value ? $0.value > $1.value : $0.key < $1.key }
            .prefix(topCount)
            .map { HistoryStats.NamedCount(name: $0.key, plays: $0.value) }
    }

    func getDatabaseSize() -> String {
        do {
            let container = modelContext.container
            if let url = container.configurations.first?.url {
                let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
                if let fileSize = attributes[.size] as? Int64 {
                    return formatFileSize(fileSize)
                }
            }
        } catch {
            System.log("Failed to get database size: \(error)", level: .error)
        }
        return "Unknown"
    }
    
    private func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
    
    private func compressArtwork(_ image: NSImage) -> Data? {
        let thumbnailSize = NSSize(width: 100, height: 100)
        
        guard let resizedImage = resizeImage(image, to: thumbnailSize) else {
            return nil
        }
        
        guard let cgImage = resizedImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return nil
        }
        
        let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
        
        return bitmapRep.representation(using: .jpeg, properties: [.compressionFactor: 0.5])
    }
    
    private func resizeImage(_ image: NSImage, to size: NSSize) -> NSImage? {
        let imageSize = image.size
        guard imageSize.width > 0, imageSize.height > 0 else { return nil }

        let aspectRatio = imageSize.width / imageSize.height
        let targetAspectRatio = size.width / size.height

        let drawRect: NSRect
        if aspectRatio > targetAspectRatio {
            let drawWidth = size.height * aspectRatio
            drawRect = NSRect(x: (size.width - drawWidth) / 2, y: 0, width: drawWidth, height: size.height)
        } else {
            let drawHeight = size.width / aspectRatio
            drawRect = NSRect(x: 0, y: (size.height - drawHeight) / 2, width: size.width, height: drawHeight)
        }

        return NSImage(size: size, flipped: false) { _ in
            image.draw(in: drawRect)
            return true
        }
    }
    
    private func getOrCreateAlbumArtwork(for track: MusicTrack) async -> AlbumArtwork? {
        guard let album = track.album else { return nil }
        
        let trackArtist = track.artist
        let descriptor = FetchDescriptor<AlbumArtwork>(
            predicate: #Predicate<AlbumArtwork> { artwork in
                artwork.album == album && artwork.artist == trackArtist
            }
        )
        
        do {
            if let existingArtwork = try modelContext.fetch(descriptor).first {
                return existingArtwork
            }
            
            if let artwork = track.artwork {
                let artworkData: Data?
                
                switch artwork {
                case .url(let url):
                    artworkData = await downloadArtworkData(from: url)
                case .image(let image):
                    artworkData = compressArtwork(image)
                }
                
                if let artworkData {
                    // Re-check after the await: another save for the same album
                    // may have inserted while the download was in flight.
                    if let raced = try modelContext.fetch(descriptor).first {
                        return raced
                    }

                    let newArtwork = AlbumArtwork(
                        album: album,
                        artist: track.artist,
                        artworkData: artworkData
                    )
                    modelContext.insert(newArtwork)
                    return newArtwork
                }
            }
            
        } catch {
            System.log("Failed to fetch/create artwork: \(error)", level: .error)
        }
        
        return nil
    }
    
    func artworkImage(for entry: SongHistory) -> NSImage? {
        guard let artwork = entry.artwork else { return nil }

        let key = artwork.id as NSUUID
        if let cached = imageCache.object(forKey: key) { return cached }

        guard let image = NSImage(data: artwork.artworkData) else { return nil }
        imageCache.setObject(image, forKey: key)
        return image
    }
} 
