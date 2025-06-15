//
//  HistoryView.swift
//  Notify
//
//  Created by AI Assistant
//

import SwiftUI
import AppKit

struct HistoryView: View {
    @EnvironmentObject var historyInteractor: HistoryInteractor
    @EnvironmentObject var musicInteractor: MusicInteractor
    @State private var showingClearAlert = false
    @State private var selectedEntry: SongHistory?
    
    var body: some View {
        NavigationView {
            // Left sidebar - Song list
            VStack(spacing: 0) {
                HeaderStatsView()
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor))
                
                Divider()
                
                if historyInteractor.recentHistory.isEmpty {
                    EmptyHistoryView()
                } else {
                    ScrollViewReader { proxy in
                        List(selection: $selectedEntry) {
                            ForEach(historyInteractor.recentHistory, id: \.id) { entry in
                                HistoryRowView(
                                    entry: entry, 
                                    isSelected: selectedEntry?.id == entry.id,
                                    isCurrentlyPlaying: isCurrentlyPlaying(entry)
                                )
                                .tag(entry)
                                .id(entry.id)
                                .onTapGesture {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        selectedEntry = entry
                                    }
                                }
                                .contextMenu {
                                    Button("Delete") {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            historyInteractor.deleteHistoryEntry(entry)
                                            if selectedEntry?.id == entry.id {
                                                selectedEntry = nil
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .listStyle(PlainListStyle())
                        .animation(.easeInOut(duration: 0.3), value: historyInteractor.recentHistory)
                        .onChange(of: historyInteractor.recentHistory) { newHistory in
                            // Scroll to top when new song is added
                            if let firstEntry = newHistory.first {
                                withAnimation(.easeInOut(duration: 0.5)) {
                                    proxy.scrollTo(firstEntry.id, anchor: .top)
                                }
                            }
                        }
                    }
                }
                
                Spacer()
                
                HStack {
                    Button("Clear All") {
                        showingClearAlert = true
                    }
                    .foregroundColor(.red)
                    
                    Spacer()
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
            }
            .frame(minWidth: 320)
            
            // Right detail view
            DetailView(selectedEntry: selectedEntry)
                .frame(minWidth: 400)
        }
        .navigationTitle("Song History")
        .frame(minWidth: 720, minHeight: 400)
        .alert("Clear History", isPresented: $showingClearAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear All", role: .destructive) {
                withAnimation(.easeInOut(duration: 0.4)) {
                    historyInteractor.clearAllHistory()
                    selectedEntry = nil
                }
            }
        } message: {
            Text("This will permanently delete all song history. This action cannot be undone.")
        }
        .onAppear {
            // Auto-select first entry if available
            if selectedEntry == nil && !historyInteractor.recentHistory.isEmpty {
                selectedEntry = historyInteractor.recentHistory.first
            }
        }
        .onChange(of: historyInteractor.recentHistory) { newHistory in
            // Update selection if current selection is no longer available
            if let selected = selectedEntry,
               !newHistory.contains(where: { $0.id == selected.id }) {
                selectedEntry = newHistory.first
            } else if selectedEntry == nil && !newHistory.isEmpty {
                selectedEntry = newHistory.first
            }
        }
    }
    
    private func isCurrentlyPlaying(_ entry: SongHistory) -> Bool {
        guard let currentTrack = musicInteractor.currentTrack,
              musicInteractor.currentState == .playing else { return false }
        
        // Only highlight if this is the same track AND it's the most recent entry for this track
        let isSameTrack = entry.trackId == currentTrack.id && 
                         entry.artist == currentTrack.artist &&
                         entry.trackName == currentTrack.name
        
        guard isSameTrack else { return false }
        
        // Check if this is the most recent entry for this track
        let mostRecentEntry = historyInteractor.recentHistory
            .filter { $0.trackId == currentTrack.id && $0.artist == currentTrack.artist && $0.trackName == currentTrack.name }
            .max(by: { $0.playedAt < $1.playedAt })
        
        return entry.id == mostRecentEntry?.id
    }
}

struct DetailView: View {
    let selectedEntry: SongHistory?
    
    var body: some View {
        Group {
            if let entry = selectedEntry {
                ScrollView {
                    VStack(spacing: 0) {
                        DetailHeaderView(entry: entry)
                        DetailStatsView(entry: entry)
                    }
                }
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .trailing)),
                    removal: .opacity.combined(with: .move(edge: .leading))
                ))
                .id(entry.id)
            } else {
                DetailEmptyStateView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: selectedEntry?.id)
    }
}

struct DetailHeaderView: View {
    let entry: SongHistory
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer(minLength: 30)
            
            DetailArtworkView(entry: entry)
            DetailSongInfoView(entry: entry)
            
            Spacer(minLength: 40)
        }
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [Color(NSColor.controlBackgroundColor).opacity(0.3), Color.clear],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

struct DetailArtworkView: View {
    let entry: SongHistory
    
    var body: some View {
        Group {
            if let artworkData = entry.artworkData,
               let image = NSImage(data: artworkData) {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(NSColor.controlBackgroundColor))
                    
                    Image(systemName: "music.note")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(width: 220, height: 220)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.2), radius: 12, x: 0, y: 6)
        .scaleEffect(1.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: entry.id)
    }
}

struct DetailSongInfoView: View {
    let entry: SongHistory
    
    var body: some View {
        VStack(spacing: 8) {
            Text(entry.trackName)
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .transition(.opacity.combined(with: .slide))
            
            Text(entry.artist)
                .font(.title2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .transition(.opacity.combined(with: .slide))
            
            if let album = entry.album {
                Text(album)
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .transition(.opacity.combined(with: .slide))
            }
        }
        .padding(.horizontal, 24)
    }
}

struct DetailStatsView: View {
    let entry: SongHistory
    @EnvironmentObject var historyInteractor: HistoryInteractor
    
    var body: some View {
        let playCounts = historyInteractor.getPlayCounts(for: entry)
        
        VStack(spacing: 16) {
            Text("Details")
                .font(.headline)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
            
            // Essential info - 4 columns, smaller cards
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 4), spacing: 10) {
                CompactStatView(title: "Duration", value: entry.formattedDuration, icon: "clock.fill")
                CompactStatView(title: "Song Plays", value: "\(playCounts.songPlays)", icon: "repeat")
                CompactStatView(title: "Artist Plays", value: "\(playCounts.artistPlays)", icon: "person.fill")
                CompactStatView(title: "App", value: entry.musicApp, icon: "music.note.tv.fill")
            }
            .padding(.horizontal, 24)
            
            // Album plays if available
            if let album = entry.album {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 2), spacing: 10) {
                    CompactStatView(title: "Album Plays", value: "\(playCounts.albumPlays)", icon: "square.stack.fill")
                    CompactStatView(title: "Played At", value: entry.formattedPlayedAt, icon: "calendar")
                }
                .padding(.horizontal, 24)
            }
            
            // Extended metadata if available
            if hasExtendedMetadata {
                VStack(spacing: 12) {
                    Text("Metadata")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                        if let genre = entry.genre {
                            MiniStatView(title: "Genre", value: genre, icon: "music.quarternote.3")
                        }
                        if entry.year != nil {
                            MiniStatView(title: "Year", value: entry.formattedYear, icon: "calendar")
                        }
                        if entry.trackNumber != nil {
                            MiniStatView(title: "Track", value: entry.formattedTrackNumber, icon: "number")
                        }
                        if entry.rating != nil {
                            MiniStatView(title: "Rating", value: entry.formattedRating, icon: "star.fill")
                        }
                        if entry.bpm != nil {
                            MiniStatView(title: "BPM", value: entry.formattedBpm, icon: "metronome")
                        }
                        if entry.bitRate != nil {
                            MiniStatView(title: "Quality", value: entry.formattedBitRate, icon: "waveform")
                        }
                        if let composer = entry.composer {
                            MiniStatView(title: "Composer", value: composer, icon: "music.note.list")
                        }
                        if let albumArtist = entry.albumArtist, albumArtist != entry.artist {
                            MiniStatView(title: "Album Artist", value: albumArtist, icon: "person.2.fill")
                        }
                    }
                    .padding(.horizontal, 24)
                }
            }
            
            Spacer(minLength: 20)
        }
    }
    
    private var hasExtendedMetadata: Bool {
        entry.genre != nil || entry.year != nil || entry.trackNumber != nil || 
        entry.rating != nil || entry.bpm != nil || entry.bitRate != nil || 
        entry.composer != nil || (entry.albumArtist != nil && entry.albumArtist != entry.artist)
    }
}

struct DetailEmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "music.note.list")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
                .scaleEffect(0.8)
                .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true))
            
            Text("Select a song to view details")
                .font(.title2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .transition(.opacity)
    }
}

struct CompactStatView: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.appAccent)
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .tracking(0.3)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.6))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.secondary.opacity(0.1), lineWidth: 0.5)
        )
        .transition(.scale.combined(with: .opacity))
    }
}

struct MiniStatView: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.appAccent)
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
                .lineLimit(1)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .tracking(0.2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.4))
        .cornerRadius(6)
        .transition(.scale.combined(with: .opacity))
    }
}

struct HeaderStatsView: View {
    @EnvironmentObject var historyInteractor: HistoryInteractor
    
    var body: some View {
        let stats = historyInteractor.getHistoryStats()
        
        HStack(spacing: 30) {
            StatView(title: "Total Songs", value: "\(stats.totalSongs)")
            StatView(title: "Artists", value: "\(stats.uniqueArtists.count)")
            StatView(title: "Total Duration", value: formatTotalTime(stats.totalDuration))
        }
    }
    
    private func formatTotalTime(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

struct StatView: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct HistoryRowView: View {
    let entry: SongHistory
    let isSelected: Bool
    let isCurrentlyPlaying: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Group {
                    if let artworkData = entry.artworkData,
                       let image = NSImage(data: artworkData) {
                        Image(nsImage: image)
                            .resizable()
                    } else {
                        Image(systemName: "music.note")
                            .foregroundColor(.secondary)
                            .font(.title2)
                    }
                }
                .frame(width: 40, height: 40)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(6)
                .scaleEffect(isSelected ? 1.05 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: isSelected)
                
                // Currently playing indicator
                if isCurrentlyPlaying {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Image(systemName: "waveform")
                                .font(.caption2)
                                .foregroundColor(.appGreen)
                                .background(
                                    Circle()
                                        .fill(Color.black.opacity(0.7))
                                        .frame(width: 16, height: 16)
                                )
                        }
                    }
                    .frame(width: 40, height: 40)
                }
            }
            
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(entry.trackName)
                        .font(.headline)
                        .lineLimit(1)
                        .foregroundColor(isCurrentlyPlaying ? .appGreen : .primary)
                    
                    if isCurrentlyPlaying {
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.caption)
                            .foregroundColor(.appGreen)
                            .symbolEffect(.pulse, options: .repeating)
                    }
                }
                
                Text(entry.artist)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                if let album = entry.album {
                    Text(album)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            // Right side info
            VStack(alignment: .trailing, spacing: 2) {
                Text(entry.formattedPlayedAt)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(entry.musicApp)
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(entry.musicApp == "Spotify" ? Color.appGreen.opacity(0.2) : Color.blue.opacity(0.2))
                    .cornerRadius(4)
                    .scaleEffect(isSelected ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: isSelected)
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(
            Group {
                if isCurrentlyPlaying {
                    Color.appGreen.opacity(0.1)
                } else if isSelected {
                    Color.appAccent.opacity(0.1)
                } else {
                    Color.clear
                }
            }
        )
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isCurrentlyPlaying ? Color.appGreen.opacity(0.3) : Color.clear, lineWidth: 1)
        )
        .animation(.easeInOut(duration: 0.2), value: isSelected)
        .animation(.easeInOut(duration: 0.2), value: isCurrentlyPlaying)
    }
}

struct EmptyHistoryView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "music.note.list")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No Song History")
                .font(.title2)
                .fontWeight(.medium)
            
            Text("Songs you play will appear here")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

extension DateFormatter {
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
    }()
}
