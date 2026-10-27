import SwiftUI
import AppKit

struct HistoryRowView: View {
    let entry: SongHistory
    let isCurrentlyPlaying: Bool
    @Environment(HistoryInteractor.self) var historyInteractor

    /// Decoded once per row via `.task`, never in `body` — the decode is a
    /// synchronous JPEG → NSImage on the main actor.
    @State private var artwork: NSImage?

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
                    if let artwork {
                        Image(nsImage: artwork)
                            .resizable()
                            .interpolation(.medium)
                    } else {
                        Image(systemName: "music.note")
                            .foregroundStyle(.secondary)
                            .font(.title2)
                    }
                }
                .frame(width: 40, height: 40)
                .clipShape(RoundedRectangle(cornerRadius: 6))

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
            }
        }
        .padding(.vertical, 4)
        .task(id: entry.id) {
            artwork = historyInteractor.artworkImage(for: entry)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            isCurrentlyPlaying
                ? "Now playing, \(entry.trackName) by \(entry.artist), \(entry.musicApp), \(entry.formattedPlayedAt)"
                : "\(entry.trackName) by \(entry.artist), \(entry.musicApp), \(entry.formattedPlayedAt)"
        )
    }
}
