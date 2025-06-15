//
//  HistoryInteractor.swift
//  Notify
//
//  Created by AI Assistant
//

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
    
    func saveSong(from track: MusicTrack, musicApp: SupportedMusicApplication) {
        Task {
            var artworkData: Data?
            
            if let artwork = track.artwork {
                switch artwork {
                case .image(let image):
                    artworkData = image.tiffRepresentation
                case .url(let url):
                    // Download artwork from URL for Spotify
                    if let image = await downloadArtwork(from: url) {
                        artworkData = image.tiffRepresentation
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
                loadRecentHistory() // Refresh the list
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
} 
