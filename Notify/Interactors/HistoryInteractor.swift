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
            let sizeBefore = getCurrentDatabaseSize()
            var artworkData: Data?
            
            if let artwork = track.artwork, shouldStoreArtwork(for: track) {
                switch artwork {
                case .image(let image):
                    artworkData = compressArtwork(image)
                case .url(let url):
                    if let image = await downloadArtwork(from: url) {
                        artworkData = compressArtwork(image)
                    }
                }
            }
            
            let historyEntry = SongHistory(
                trackId: track.id,
                trackName: track.name,
                artist: track.artist,
                album: track.album,
                albumArtist: track.albumArtist,
                duration: track.duration,
                playedAt: Date(),
                musicApp: musicApp.appName,
                artworkData: artworkData,
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

                forceCheckpoint()
                
                let sizeAfter = getCurrentDatabaseSize()
                let artworkNote = artworkData != nil ? " (with \(formatFileSize(Int64(artworkData!.count))) artwork)" : " (no artwork - duplicate album)"
                
                System.log("Size before: \(sizeBefore), Size after: \(sizeAfter), Diff: \(sizeAfter - sizeBefore)", level: .info)
                logDatabaseSizeChange(operation: "Added song '\(track.name)'\(artworkNote)", sizeBefore: sizeBefore, sizeAfter: sizeAfter)
                
                System.log("Saved song to history: \(track.name) by \(track.artist)", level: .info)
            } catch {
                System.log("Failed to save song history: \(error)", level: .error)
            }
        }
    }
    
    func saveSong(from track: MusicTrack, musicApp: SupportedMusicApplication) {
        Task {
            var artworkData: Data?
            
            if let artwork = track.artwork, shouldStoreArtwork(for: track) {
                switch artwork {
                case .image(let image):
                    artworkData = compressArtwork(image)
                case .url(let url):
                    if let image = await downloadArtwork(from: url) {
                        artworkData = compressArtwork(image)
                    }
                }
            }
            
            let historyEntry = SongHistory(
                trackId: track.id,
                trackName: track.name,
                artist: track.artist,
                album: track.album,
                albumArtist: track.albumArtist,
                duration: track.duration,
                playedAt: Date(),
                musicApp: musicApp.appName,
                artworkData: artworkData,
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
        let sizeBefore = getCurrentDatabaseSize()
        let entryName = entry.trackName
        let hasArtwork = entry.artworkData != nil
        
        modelContext.delete(entry)
        
        do {
            try modelContext.save()
            loadRecentHistory()
            
            let sizeAfter = getCurrentDatabaseSize()
            let artworkNote = hasArtwork ? " (with artwork)" : " (no artwork)"
            logDatabaseSizeChange(operation: "Deleted song '\(entryName)'\(artworkNote)", sizeBefore: sizeBefore, sizeAfter: sizeAfter)
        } catch {
            System.log("Failed to delete history entry: \(error)", level: .error)
        }
    }
    
    func clearAllHistory() {
        let sizeBefore = getCurrentDatabaseSize()
        
        do {
            try modelContext.delete(model: SongHistory.self)
            try modelContext.save()
            
            try modelContext.save()
            
            loadRecentHistory()
            
            let sizeAfter = getCurrentDatabaseSize()
            logDatabaseSizeChange(operation: "Cleared all history", sizeBefore: sizeBefore, sizeAfter: sizeAfter)
            
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
                let _ = try FileManager.default.attributesOfItem(atPath: url.path)
                
                let totalSize = getTotalDatabaseSize(baseURL: url)
                return formatFileSize(totalSize)
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
    
    private func logDatabaseSizeChange(operation: String, sizeBefore: Int64, sizeAfter: Int64) {
        let beforeStr = formatFileSize(sizeBefore)
        let afterStr = formatFileSize(sizeAfter)
        let diff = sizeAfter - sizeBefore
        let diffStr = formatFileSize(abs(diff))
        
        if diff > 0 {
            System.log("\(operation): Database grew from \(beforeStr) to \(afterStr) (+\(diffStr))", level: .info)
        } else if diff < 0 {
            System.log("\(operation): Database shrank from \(beforeStr) to \(afterStr) (-\(diffStr))", level: .info)
        } else {
            System.log("\(operation): Database size unchanged at \(beforeStr)", level: .info)
        }
    }
    
    private func getCurrentDatabaseSize() -> Int64 {
        do {
            let container = modelContext.container
            if let url = container.configurations.first?.url {
                System.log("Database URL: \(url.path)", level: .info)
                
                let fileExists = FileManager.default.fileExists(atPath: url.path)
                System.log("Database file exists: \(fileExists)", level: .info)
                
                if fileExists {
                    let totalSize = getTotalDatabaseSize(baseURL: url)
                    System.log("Total database size: \(totalSize) bytes (\(formatFileSize(totalSize)))", level: .info)
                    return totalSize
                } else {
                    System.log("Database file does not exist at path: \(url.path)", level: .warning)
                }
            } else {
                System.log("Could not get database URL from container", level: .error)
            }
        } catch {
            System.log("Failed to get current database size: \(error)", level: .error)
        }
        return 0
    }
    
    private func getTotalDatabaseSize(baseURL: URL) -> Int64 {
        var totalSize: Int64 = 0
        let fileManager = FileManager.default
        
        System.log("Checking database files at base path: \(baseURL.path)", level: .info)
        
        do {
            let attributes = try fileManager.attributesOfItem(atPath: baseURL.path)
            if let size = attributes[.size] as? Int64 {
                totalSize += size
                System.log("Main DB file: \(formatFileSize(size))", level: .info)
            }
        } catch {
            System.log("Failed to get main DB size: \(error)", level: .warning)
        }
        
        let walURL = URL(fileURLWithPath: baseURL.path + "-wal")
        System.log("Checking WAL file: \(walURL.path)", level: .info)
        if fileManager.fileExists(atPath: walURL.path) {
            do {
                let attributes = try fileManager.attributesOfItem(atPath: walURL.path)
                if let size = attributes[.size] as? Int64 {
                    totalSize += size
                    System.log("WAL file: \(formatFileSize(size))", level: .info)
                }
            } catch {
                System.log("Failed to get WAL size: \(error)", level: .warning)
            }
        } else {
            System.log("WAL file does not exist", level: .info)
        }
        
        let shmURL = URL(fileURLWithPath: baseURL.path + "-shm")
        System.log("Checking SHM file: \(shmURL.path)", level: .info)
        if fileManager.fileExists(atPath: shmURL.path) {
            do {
                let attributes = try fileManager.attributesOfItem(atPath: shmURL.path)
                if let size = attributes[.size] as? Int64 {
                    totalSize += size
                    System.log("SHM file: \(formatFileSize(size))", level: .info)
                }
            } catch {
                System.log("Failed to get SHM size: \(error)", level: .warning)
            }
        } else {
            System.log("SHM file does not exist", level: .info)
        }
        
        System.log("Total calculated size: \(formatFileSize(totalSize))", level: .info)
        return totalSize
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
    
    private func shouldStoreArtwork(for track: MusicTrack) -> Bool {
        guard let album = track.album else { return true }
        
        let descriptor = FetchDescriptor<SongHistory>()
        
        do {
            let existingHistory = try modelContext.fetch(descriptor)
            let hasArtworkForAlbum = existingHistory.contains { entry in
                entry.album == album && 
                entry.artist == track.artist && 
                entry.artworkData != nil
            }
            
            return !hasArtworkForAlbum
        } catch {
            return true
        }
    }
    
    func compressExistingArtwork() {
        Task {
            let sizeBefore = getCurrentDatabaseSize()
            let descriptor = FetchDescriptor<SongHistory>()
            
            do {
                let allHistory = try modelContext.fetch(descriptor)
                var compressedCount = 0
                var totalSizeSaved: Int64 = 0
                
                for entry in allHistory {
                    if let artworkData = entry.artworkData,
                       let image = NSImage(data: artworkData) {
                        if artworkData.count > 15000 {
                            if let compressedData = compressArtwork(image) {
                                let sizeSaved = artworkData.count - compressedData.count
                                totalSizeSaved += Int64(sizeSaved)
                                entry.artworkData = compressedData
                                compressedCount += 1
                            }
                        }
                    }
                }
                
                if compressedCount > 0 {
                    try modelContext.save()
                    
                    let sizeAfter = getCurrentDatabaseSize()
                    logDatabaseSizeChange(operation: "Compressed \(compressedCount) artworks (saved ~\(formatFileSize(totalSizeSaved)) in images)", sizeBefore: sizeBefore, sizeAfter: sizeAfter)
                    
                    System.log("Compressed artwork for \(compressedCount) entries", level: .info)
                    await MainActor.run {
                        loadRecentHistory()
                    }
                } else {
                    System.log("No artwork needed compression", level: .info)
                }
            } catch {
                System.log("Failed to compress existing artwork: \(error)", level: .error)
            }
        }
    }
    
    private func forceCheckpoint() {
        do {
            try modelContext.save()
            
            Thread.sleep(forTimeInterval: 0.1)
        } catch {
            System.log("Failed to force checkpoint: \(error)", level: .error)
        }
    }
} 
