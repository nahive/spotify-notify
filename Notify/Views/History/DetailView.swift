import SwiftUI

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
        VStack(spacing: 16) {
            Spacer(minLength: 20)
            
            DetailArtworkView(entry: entry)
            DetailSongInfoView(entry: entry)
            
            Spacer(minLength: 24)
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
    @EnvironmentObject var historyInteractor: HistoryInteractor
    
    var body: some View {
        Group {
            if let artworkData = historyInteractor.getArtworkData(for: entry),
               let image = NSImage(data: artworkData) {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(NSColor.controlBackgroundColor))
                    
                    Image(systemName: "music.note")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(width: 140, height: 140)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.18), radius: 8, x: 0, y: 4)
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: entry.id)
    }
}

struct DetailSongInfoView: View {
    let entry: SongHistory
    
    var body: some View {
        VStack(spacing: 6) {
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
        .padding(.horizontal, 20)
    }
}

struct DetailStatsView: View {
    let entry: SongHistory
    @EnvironmentObject var historyInteractor: HistoryInteractor
    
    var body: some View {
        let playCounts = historyInteractor.getPlayCounts(for: entry)
        
        VStack(spacing: 12) {
            Text("Details")
                .font(.headline)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                CompactStatView(title: "Duration", value: entry.formattedDuration, icon: "clock.fill")
                CompactStatView(title: "Song Plays", value: "\(playCounts.songPlays)", icon: "repeat")
                CompactStatView(title: "Artist Plays", value: "\(playCounts.artistPlays)", icon: "person.fill")
                CompactStatView(title: "App", value: entry.musicApp, icon: "music.note.tv.fill")
            }
            .padding(.horizontal, 20)
            
            if entry.album != nil {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 2), spacing: 8) {
                    CompactStatView(title: "Album Plays", value: "\(playCounts.albumPlays)", icon: "square.stack.fill")
                    CompactStatView(title: "Played At", value: entry.formattedPlayedAt, icon: "calendar")
                }
                .padding(.horizontal, 20)
            }
            
            if hasExtendedMetadata {
                VStack(spacing: 10) {
                    Text("Metadata")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 4), spacing: 6) {
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
                    .padding(.horizontal, 20)
                }
            }
            
            Spacer(minLength: 12)
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
        VStack(spacing: 6) {
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
        .padding(.vertical, 10)
        .padding(.horizontal, 6)
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
        VStack(spacing: 3) {
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
        .padding(.vertical, 6)
        .padding(.horizontal, 3)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.4))
        .cornerRadius(6)
        .transition(.scale.combined(with: .opacity))
    }
}
