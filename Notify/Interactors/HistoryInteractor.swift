import Foundation
import SwiftData
import AppKit

@MainActor
final class HistoryInteractor: ObservableObject {
    private let modelContext: ModelContext
    private var lastSavedTrackId: String?
    
    @Published var recentHistory: [SongHistory] = []
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadRecentHistory()
    }
    
    func saveSongIfNeeded(from track: MusicTrack, musicApp: SupportedMusicApplication) {
        guard track.id != lastSavedTrackId else { return }
        
        Task {
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
            
            do {
                try modelContext.save()
                lastSavedTrackId = track.id
                loadRecentHistory()
                System.log("Saved song to history: \(track.name) by \(track.artist)", level: .info)
            } catch {
                System.log("Failed to save song history: \(error)", level: .error)
            }
        }
    }
    
    func saveSong(from track: MusicTrack, musicApp: SupportedMusicApplication) {
        Task {
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
            
            do {
                try modelContext.save()
                lastSavedTrackId = track.id
                loadRecentHistory()
                System.log("Saved song to history: \(track.name) by \(track.artist)", level: .info)
            } catch {
                System.log("Failed to save song history: \(error)", level: .error)
            }
        }
    }
    
    func getPlayCounts(for entry: SongHistory) -> (songPlays: Int, artistPlays: Int, albumPlays: Int) {
        let descriptor = FetchDescriptor<SongHistory>()
        
        do {
            let allHistory = try modelContext.fetch(descriptor)
            
            let songPlays = allHistory.filter { 
                $0.trackName == entry.trackName && $0.artist == entry.artist 
            }.count
            
            let artistPlays = allHistory.filter { 
                $0.artist == entry.artist 
            }.count
            
            let albumPlays = allHistory.filter { 
                $0.album == entry.album && $0.artist == entry.artist 
            }.count
            
            return (songPlays, artistPlays, albumPlays)
        } catch {
            System.log("Failed to get play counts: \(error)", level: .error)
            return (0, 0, 0)
        }
    }
    
    private func downloadArtwork(from url: URL) async -> NSImage? {
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            return NSImage(data: data)
        } catch {
            System.log("Failed to download artwork from \(url): \(error)", level: .warning)
            return nil
        }
    }
    
    func loadRecentHistory(limit: Int = 100) {
        var descriptor = FetchDescriptor<SongHistory>(
            sortBy: [SortDescriptor(\.playedAt, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        
        do {
            recentHistory = try modelContext.fetch(descriptor)
        } catch {
            System.log("Failed to load song history: \(error)", level: .error)
            recentHistory = []
        }
    }
    
    func deleteHistoryEntry(_ entry: SongHistory) {
        modelContext.delete(entry)
        
        do {
            try modelContext.save()
            loadRecentHistory()
        } catch {
            System.log("Failed to delete history entry: \(error)", level: .error)
        }
    }
    
    func clearAllHistory() {
        do {
            try modelContext.delete(model: SongHistory.self)
            try modelContext.save()
            
            // Force a second save to ensure changes are persisted
            try modelContext.save()
            
            loadRecentHistory()
            System.log("Cleared all song history", level: .info)
        } catch {
            System.log("Failed to clear history: \(error)", level: .error)
        }
    }
    
    func getHistoryStats() -> (totalSongs: Int, uniqueArtists: Set<String>, totalDuration: Int) {
        let descriptor = FetchDescriptor<SongHistory>()
        
        do {
            let allHistory = try modelContext.fetch(descriptor)
            let totalSongs = allHistory.count
            let uniqueArtists = Set(allHistory.map { $0.artist })
            
            let totalDuration = allHistory.compactMap { $0.duration }.reduce(0, +)
            
            return (totalSongs, uniqueArtists, totalDuration)
        } catch {
            System.log("Failed to get history stats: \(error)", level: .error)
            return (0, [], 0)
        }
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
        let resizedImage = NSImage(size: size)
        resizedImage.lockFocus()
        
        let imageSize = image.size
        let aspectRatio = imageSize.width / imageSize.height
        let targetAspectRatio = size.width / size.height
        
        var drawRect: NSRect
        if aspectRatio > targetAspectRatio {
            let drawWidth = size.height * aspectRatio
            drawRect = NSRect(x: (size.width - drawWidth) / 2, y: 0, width: drawWidth, height: size.height)
        } else {
            let drawHeight = size.width / aspectRatio
            drawRect = NSRect(x: 0, y: (size.height - drawHeight) / 2, width: size.width, height: drawHeight)
        }
        
        image.draw(in: drawRect)
        resizedImage.unlockFocus()
        
        return resizedImage
    }
    
    private func getOrCreateAlbumArtwork(for track: MusicTrack) async -> AlbumArtwork? {
        guard let album = track.album else { return nil }
        
        // Check if we already have artwork for this album
        let artist = track.artist
        let descriptor = FetchDescriptor<AlbumArtwork>(
            predicate: #Predicate<AlbumArtwork> { artwork in
                artwork.album == album && artwork.artist == artist
            }
        )
        
        do {
            let existingArtwork = try modelContext.fetch(descriptor)
            if let existing = existingArtwork.first {
                return existing
            }
        } catch {
            System.log("Failed to fetch existing artwork: \(error)", level: .error)
        }
        
        // No existing artwork, create new one if we have artwork data
        guard let trackArtwork = track.artwork else { return nil }
        
        var artworkData: Data?
        switch trackArtwork {
        case .image(let image):
            artworkData = compressArtwork(image)
        case .url(let url):
            if let image = await downloadArtwork(from: url) {
                artworkData = compressArtwork(image)
            }
        }
        
        guard let data = artworkData else { return nil }
        
        let albumArtwork = AlbumArtwork(album: album, artist: track.artist, artworkData: data)
        modelContext.insert(albumArtwork)
        
        do {
            try modelContext.save()
            System.log("Created new album artwork for: \(album) by \(track.artist)", level: .info)
            return albumArtwork
        } catch {
            System.log("Failed to save album artwork: \(error)", level: .error)
            return nil
        }
    }
    
    func getArtworkData(for entry: SongHistory) -> Data? {
        return entry.artwork?.artworkData
    }
} 
