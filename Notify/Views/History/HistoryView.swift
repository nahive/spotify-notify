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
    @State private var showingClearAlert = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                HeaderStatsView()
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor))
                
                Divider()
                
                if historyInteractor.recentHistory.isEmpty {
                    EmptyHistoryView()
                } else {
                    List {
                        ForEach(historyInteractor.recentHistory, id: \.id) { entry in
                            HistoryRowView(entry: entry)
                                .contextMenu {
                                    Button("Delete") {
                                        historyInteractor.deleteHistoryEntry(entry)
                                    }
                                }
                        }
                    }
                    .listStyle(PlainListStyle())
                }
                
                Spacer()
                
                HStack {
                    Button("Clear All") {
                        showingClearAlert = true
                    }
                    .foregroundColor(.red)
                    
                    Spacer()
                    
                    Button("Refresh") {
                        historyInteractor.loadRecentHistory()
                    }
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
            }
        }
        .navigationTitle("Song History")
        .frame(minWidth: 500, minHeight: 400)
        .alert("Clear History", isPresented: $showingClearAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear All", role: .destructive) {
                historyInteractor.clearAllHistory()
            }
        } message: {
            Text("This will permanently delete all song history. This action cannot be undone.")
        }
    }
}

struct HeaderStatsView: View {
    @EnvironmentObject var historyInteractor: HistoryInteractor
    
    var body: some View {
        let stats = historyInteractor.getHistoryStats()
        
        HStack(spacing: 30) {
            StatView(title: "Total Songs", value: "\(stats.totalSongs)")
            StatView(title: "Artists", value: "\(stats.uniqueArtists.count)")
            StatView(title: "Listening Time", value: formatTotalTime(stats.totalListeningTime))
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
    
    var body: some View {
        HStack(spacing: 12) {
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
            
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.trackName)
                    .font(.headline)
                    .lineLimit(1)
                
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
                
                Text(entry.formattedDuration)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(entry.musicApp)
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(entry.musicApp == "Spotify" ? Color.green.opacity(0.2) : Color.blue.opacity(0.2))
                    .cornerRadius(4)
            }
        }
        .padding(.vertical, 4)
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
