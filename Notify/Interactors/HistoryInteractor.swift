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
        var artworkData: Data?
        if case let .image(image) = track.artwork {
            artworkData = image.tiffRepresentation
        }
        
        let historyEntry = SongHistory(
            trackId: track.id,
            trackName: track.name,
            artist: track.artist,
            album: track.album,
            duration: track.duration,
            playedAt: Date(),
            musicApp: musicApp.appName,
            artworkData: artworkData
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
    
    func getHistoryStats() -> (totalSongs: Int, uniqueArtists: Set<String>, totalListeningTime: Int) {
        let descriptor = FetchDescriptor<SongHistory>()
        
        do {
            let allHistory = try modelContext.fetch(descriptor)
            let totalSongs = allHistory.count
            let uniqueArtists = Set(allHistory.map { $0.artist })
            let totalListeningTime = allHistory.compactMap { $0.duration }.reduce(0, +)
            
            return (totalSongs, uniqueArtists, totalListeningTime)
        } catch {
            System.log("Failed to get history stats: \(error)", level: .error)
            return (0, [], 0)
        }
    }
} 
