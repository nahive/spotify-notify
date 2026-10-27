import SwiftUI

struct HistoryView: View {
    @Environment(HistoryInteractor.self) private var historyInteractor
    @Environment(MusicInteractor.self) private var musicInteractor

    @State private var selection: UUID?
    @State private var showingClearAlert = false
    @State private var databaseSize = "—"
    @State private var stats = HistoryStats.empty

    private var entries: [SongHistory] { historyInteractor.entries }

    private var selectedEntry: SongHistory? {
        entries.first { $0.id == selection }
    }

    var body: some View {
        @Bindable var historyInteractor = historyInteractor

        NavigationSplitView {
            // Hoisted: `currentlyPlayingId` scans the whole array, so reading it
            // per row would make list layout quadratic.
            let playingId = currentlyPlayingId

            List(selection: $selection) {
                ForEach(entries, id: \.id) { entry in
                    HistoryRowView(entry: entry, isCurrentlyPlaying: entry.id == playingId)
                }

                if historyInteractor.hasMore {
                    ProgressView()
                        .controlSize(.small)
                        .frame(maxWidth: .infinity)
                        .listRowSeparator(.hidden)
                        // Paging trigger: appears only once the user scrolls to
                        // the end of the loaded page.
                        .onAppear { historyInteractor.loadMore() }
                }
            }
            .listStyle(.inset)
            .contextMenu(forSelectionType: UUID.self) { ids in
                if let entry = entry(for: ids) {
                    HistoryEntryActions(entry: entry, onDelete: { delete(entry) })
                }
            } primaryAction: { ids in
                if let entry = entry(for: ids) {
                    play(entry)
                }
            }
            .searchable(text: $historyInteractor.query, placement: .sidebar, prompt: "Search songs, artists, albums")
            .onDeleteCommand {
                if let selectedEntry { delete(selectedEntry) }
            }
            .safeAreaInset(edge: .top) {
                VStack(spacing: 0) {
                    HeaderStatsView(stats: stats)
                        .padding()
                    Divider()
                }
                .background(.bar)
            }
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 0) {
                    Divider()
                    footer
                        .padding()
                }
                .background(.bar)
            }
            .overlay {
                if entries.isEmpty {
                    if historyInteractor.query.isEmpty {
                        ContentUnavailableView(
                            "No Song History",
                            systemImage: "music.note.list",
                            description: Text("Songs you play in Spotify or Apple Music will appear here.")
                        )
                    } else {
                        ContentUnavailableView.search(text: historyInteractor.query)
                    }
                }
            }
            .navigationSplitViewColumnWidth(min: 320, ideal: 360)
        } detail: {
            Group {
                if let selectedEntry {
                    DetailView(entry: selectedEntry)
                } else {
                    HistoryOverviewView(stats: stats)
                }
            }
            .frame(minWidth: 400)
            .animation(.easeInOut(duration: 0.3), value: selection)
        }
        .navigationTitle("Song History")
        .toolbar {
            ToolbarItem {
                Button {
                    selection = nil
                } label: {
                    Label("Overview", systemImage: "chart.bar.xaxis")
                }
                .help("Show listening overview")
                .disabled(selection == nil)
            }
        }
        .frame(minWidth: 720, minHeight: 400)
        .alert("Clear History", isPresented: $showingClearAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear All", role: .destructive) {
                historyInteractor.clearAllHistory()
                selection = nil
            }
        } message: {
            Text("This will permanently delete all song history. This action cannot be undone.")
        }
        .task(id: historyInteractor.revision) {
            refresh()
        }
        .onChange(of: entries) { _, newEntries in
            // Deleted or filtered out: fall back to the overview.
            if let selection, !newEntries.contains(where: { $0.id == selection }) {
                self.selection = nil
            }
        }
    }

    private var footer: some View {
        HStack {
            Button("Clear All") {
                showingClearAlert = true
            }
            .foregroundStyle(.red)
            .disabled(stats.totalSongs == 0)

            Spacer()

            Text("Database: \(databaseSize)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var currentlyPlayingId: UUID? {
        guard let track = musicInteractor.currentTrack, musicInteractor.currentState == .playing else { return nil }
        return entries
            .filter { $0.trackId == track.id && $0.artist == track.artist && $0.trackName == track.name }
            .max(by: { $0.playedAt < $1.playedAt })?.id
    }

    private func entry(for ids: Set<UUID>) -> SongHistory? {
        guard ids.count == 1, let id = ids.first else { return nil }
        return entries.first { $0.id == id }
    }

    private func play(_ entry: SongHistory) {
        guard let application = entry.application else { return }
        musicInteractor.play(trackId: entry.trackId, in: application)
    }

    private func delete(_ entry: SongHistory) {
        if selection == entry.id { selection = nil }
        historyInteractor.deleteHistoryEntry(entry)
    }

    private func refresh() {
        stats = historyInteractor.getHistoryStats()
        databaseSize = historyInteractor.getDatabaseSize()
    }
}

// MARK: - Entry actions

/// Menu items shared by the list's context menu and the detail pane.
struct HistoryEntryActions: View {
    let entry: SongHistory
    var onDelete: (() -> Void)?

    @Environment(MusicInteractor.self) private var musicInteractor

    var body: some View {
        if let application = entry.application {
            Button {
                musicInteractor.play(trackId: entry.trackId, in: application)
            } label: {
                Label("Play in \(application.appName)", systemImage: "play.fill")
            }
        }

        if let link = entry.webLink {
            ShareLink(item: link) {
                Label("Share…", systemImage: "square.and.arrow.up")
            }
        }

        Button {
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.setString(entry.webLink?.absoluteString ?? entry.displayTitle, forType: .string)
        } label: {
            Label(entry.webLink == nil ? "Copy Song Info" : "Copy Song Link", systemImage: "doc.on.doc")
        }

        if let onDelete {
            Divider()
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

extension SongHistory {
    var application: SupportedMusicApplication? {
        SupportedMusicApplication(appName: musicApp)
    }

    var displayTitle: String {
        "\(trackName) — \(artist)"
    }

    /// A browser link for Spotify tracks, derived from the stored
    /// `spotify:track:<id>` URI. Apple Music's scripting interface exposes no
    /// catalog id, so its rows have none.
    var webLink: URL? {
        let uri = spotifyUrl ?? trackId
        let parts = uri.split(separator: ":")
        guard parts.count == 3, parts[0] == "spotify", parts[1] == "track" else { return nil }
        return URL(string: "https://open.spotify.com/track/\(parts[2])")
    }
}

private struct HeaderStatsView: View {
    let stats: HistoryStats

    var body: some View {
        HStack(spacing: 30) {
            StatView(title: "Total Songs", value: "\(stats.totalSongs)")
            StatView(title: "Artists", value: "\(stats.uniqueArtists)")
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

private struct StatView: View {
    let title: String
    let value: String

    var body: some View {
        VStack {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
