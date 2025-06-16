import SwiftUI
import AppKit

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
                
                if isCurrentlyPlaying {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Image(systemName: "waveform")
                                .font(.caption2)
                                .foregroundColor(.appAccent)
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
                        .foregroundColor(isCurrentlyPlaying ? .appAccent : .primary)
                    
                    if isCurrentlyPlaying {
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.caption)
                            .foregroundColor(.appAccent)
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
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(entry.formattedPlayedAt)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(entry.musicApp)
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(entry.musicApp == "Spotify" ? Color.appAccent.opacity(0.2) : Color.blue.opacity(0.2))
                    .cornerRadius(4)
                    .scaleEffect(isSelected ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: isSelected)
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(
            Group {
                if isCurrentlyPlaying || isSelected {
                    Color.appAccent.opacity(0.1)
                } else {
                    Color.clear
                }
            }
        )
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isCurrentlyPlaying ? Color.appAccent.opacity(0.3) : Color.clear, lineWidth: 1)
        )
        .animation(.easeInOut(duration: 0.2), value: isSelected)
        .animation(.easeInOut(duration: 0.2), value: isCurrentlyPlaying)
    }
} 