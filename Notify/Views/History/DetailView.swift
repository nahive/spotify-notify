import SwiftUI
import Charts

struct DetailView: View {
    let entry: SongHistory

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                DetailHeaderView(entry: entry)
                DetailStatsView(entry: entry)
                    .padding(.top, 16)
            }
            .padding(.bottom, 20)
        }
    }
}

/// Full-bleed hero: the artwork, blurred and dimmed, behind a sharp copy and
/// the track details.
private struct DetailHeaderView: View {
    let entry: SongHistory
    @Environment(HistoryInteractor.self) private var historyInteractor

    @State private var artwork: NSImage?

    var body: some View {
        VStack(spacing: 14) {
            DetailArtworkView(artwork: artwork)
            DetailSongInfoView(entry: entry)
            HStack(spacing: 10) {
                HistoryEntryActions(entry: entry)
            }
            .labelStyle(.iconOnly)
            .buttonStyle(.glass)
            .controlSize(.large)
        }
        .padding(.top, 28)
        .padding(.bottom, 24)
        .frame(maxWidth: .infinity)
        .background {
            ZStack {
                if let artwork {
                    Image(nsImage: artwork)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .blur(radius: 40, opaque: true)
                        .saturation(1.4)
                        .transition(.opacity)
                }
                // Fades the hero into the window background so the stats
                // below don't sit on a hard edge.
                LinearGradient(
                    colors: [.clear, Color(nsColor: .windowBackgroundColor)],
                    startPoint: .center,
                    endPoint: .bottom
                )
            }
            .clipped()
        }
        .task(id: entry.id) {
            withAnimation(.easeInOut(duration: 0.3)) {
                artwork = historyInteractor.artworkImage(for: entry)
            }
        }
    }
}

private struct DetailArtworkView: View {
    let artwork: NSImage?

    var body: some View {
        Group {
            if let artwork {
                Image(nsImage: artwork)
                    .resizable()
                    .interpolation(.medium)
                    .aspectRatio(contentMode: .fill)
            } else {
                Image(systemName: "music.note")
                    .font(.system(size: 40))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.quaternary)
            }
        }
        .frame(width: 160, height: 160)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.3), radius: 16, y: 8)
    }
}

private struct DetailSongInfoView: View {
    let entry: SongHistory

    var body: some View {
        VStack(spacing: 4) {
            Text(entry.trackName)
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            Text(entry.artist)
                .font(.title3)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if let album = entry.album {
                Text(album)
                    .font(.headline)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, 20)
    }
}

private struct DetailStatsView: View {
    let entry: SongHistory
    @Environment(HistoryInteractor.self) var historyInteractor
    
    /// Three `fetchCount` queries — resolved once per selection, never in `body`.
    @State private var playCounts = (songPlays: 0, artistPlays: 0, albumPlays: 0)

    var body: some View {
        VStack(spacing: 12) {
            Text("Details")
                .font(.headline)
                .foregroundStyle(.secondary)
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
                        .foregroundStyle(.secondary)
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
        }
        .task(id: entry.id) {
            playCounts = historyInteractor.getPlayCounts(for: entry)
        }
    }
    
    private var hasExtendedMetadata: Bool {
        entry.genre != nil || entry.year != nil || entry.trackNumber != nil || 
        entry.rating != nil || entry.bpm != nil || entry.bitRate != nil || 
        entry.composer != nil || (entry.albumArtist != nil && entry.albumArtist != entry.artist)
    }
}

/// Shown when no song is selected: plays per day and the most played
/// artists and albums.
struct HistoryOverviewView: View {
    let stats: HistoryStats

    var body: some View {
        if stats.totalSongs == 0 {
            ContentUnavailableView(
                "No Listening Data Yet",
                systemImage: "chart.bar",
                description: Text("Charts appear once songs are in your history.")
            )
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    OverviewSection(title: "Last \(HistoryInteractor.chartDays) Days") {
                        Chart(stats.playsPerDay) { day in
                            BarMark(
                                x: .value("Day", day.day, unit: .day),
                                y: .value("Plays", day.plays)
                            )
                            .foregroundStyle(Color.appAccent.gradient)
                            .cornerRadius(3)
                        }
                        .chartXAxis {
                            AxisMarks(values: .stride(by: .day, count: 2)) {
                                AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                            }
                        }
                        .frame(height: 160)
                    }

                    OverviewSection(title: "Top Artists") {
                        TopList(items: stats.topArtists)
                    }

                    if !stats.topAlbums.isEmpty {
                        OverviewSection(title: "Top Albums") {
                            TopList(items: stats.topAlbums)
                        }
                    }
                }
                .padding(20)
            }
        }
    }
}

private struct OverviewSection<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.secondary)
            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

/// Ranked rows rather than a Chart: Charts lays category labels over the bars
/// once names get long, and a top-5 list needs no axis anyway.
private struct TopList: View {
    let items: [HistoryStats.NamedCount]

    private var maxPlays: Int {
        max(items.map(\.plays).max() ?? 1, 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(items) { item in
                VStack(alignment: .leading, spacing: 5) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(item.name)
                            .font(.subheadline)
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .help(item.name)
                        Spacer(minLength: 8)
                        Text("\(item.plays)")
                            .font(.subheadline.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }

                    GeometryReader { geo in
                        Capsule()
                            .fill(Color.appAccent.gradient)
                            .frame(width: max(6, geo.size.width * CGFloat(item.plays) / CGFloat(maxPlays)))
                    }
                    .frame(height: 6)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(item.name), \(item.plays) plays")
            }
        }
    }
}

private struct CompactStatView: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.appAccent)
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(0.3)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .padding(.horizontal, 6)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.secondary.opacity(0.1), lineWidth: 0.5)
        )
    }
}

private struct MiniStatView: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 3) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.appAccent)
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
                .lineLimit(1)
            
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(0.2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .padding(.horizontal, 3)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}
