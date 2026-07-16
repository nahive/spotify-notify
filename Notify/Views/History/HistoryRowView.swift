import SwiftUI
import AppKit

struct HistoryRowView: View {
    let entry: SongHistory
    let isSelected: Bool
    let isCurrentlyPlaying: Bool
    @Environment(HistoryInteractor.self) var historyInteractor
    
    private var musicAppColor: Color {
        switch entry.musicApp {
        case "Spotify":
            return .spotify
        case "Apple Music", "Music":
            return .appleMusic
        default:
            return .appAccent
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Group {
                    if let image = historyInteractor.artworkImage(for: entry) {
                        Image(nsImage: image)
                            .resizable()
                    } else {
                        Image(systemName: "music.note")
                            .foregroundStyle(.secondary)
                            .font(.title2)
                    }
                }
                .frame(width: 40, height: 40)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .scaleEffect(isSelected ? 1.05 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: isSelected)
                
                if isCurrentlyPlaying {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Image(systemName: "waveform")
                                .font(.caption2)
                                .foregroundStyle(musicAppColor)
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
                        .foregroundStyle(isCurrentlyPlaying ? musicAppColor : .primary)
                    
                    if isCurrentlyPlaying {
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.caption)
                            .foregroundStyle(musicAppColor)
                            .symbolEffect(.pulse, options: .repeating)
                    }
                }
                
                Text(entry.artist)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                
                if let album = entry.album {
                    Text(album)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(entry.formattedPlayedAt)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Text(entry.musicApp)
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(musicAppColor.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .scaleEffect(isSelected ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: isSelected)
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(
            Group {
                if isCurrentlyPlaying || isSelected {
                    musicAppColor.opacity(0.1)
                } else {
                    Color.clear
                }
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isCurrentlyPlaying ? musicAppColor.opacity(0.3) : Color.clear, lineWidth: 1)
        )
        .animation(.easeInOut(duration: 0.2), value: isSelected)
        .animation(.easeInOut(duration: 0.2), value: isCurrentlyPlaying)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(entry.trackName) by \(entry.artist), \(entry.musicApp)")
    }
} 
