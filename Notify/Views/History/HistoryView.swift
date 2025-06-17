import SwiftUI
import AppKit

struct HistoryView: View {
    @EnvironmentObject var historyInteractor: HistoryInteractor
    @EnvironmentObject var musicInteractor: MusicInteractor
    @State private var showingClearAlert = false
    @State private var selectedEntry: SongHistory?
    @State private var databaseSize = "Calculating..."
    
    var body: some View {
        NavigationView {
            ZStack {
                if historyInteractor.recentHistory.isEmpty {
                    EmptyHistoryView()
                        .padding(.top, 80)
                        .padding(.bottom, 60)
                } else {
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 0) {
                                Color.clear.frame(height: 80)
                                    .id("topSpacer")
                                
                                ForEach(historyInteractor.recentHistory, id: \.id) { entry in
                                    HistoryRowView(
                                        entry: entry, 
                                        isSelected: selectedEntry?.id == entry.id,
                                        isCurrentlyPlaying: isCurrentlyPlaying(entry)
                                    )
                                    .id(entry.id)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        withAnimation(.easeInOut(duration: 0.2)) {
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
                                            updateDatabaseSize()
                                        }
                                    }
                                }
                                
                                Color.clear.frame(height: 60)
                            }
                        }
                        .scrollIndicators(.hidden)
                        .animation(.easeInOut(duration: 0.3), value: historyInteractor.recentHistory)
                        .onChange(of: historyInteractor.recentHistory) { _, newHistory in
                            if !newHistory.isEmpty {
                                withAnimation(.easeInOut(duration: 0.5)) {
                                    proxy.scrollTo("topSpacer", anchor: .top)
                                }

                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    updateDatabaseSize()
                                }
                            }
                        }
                    }
                }
                
                VStack {
                    VStack(spacing: 0) {
                        HeaderStatsView()
                            .padding()
                        Divider()
                    }
                    .background(.ultraThinMaterial, in: Rectangle())
                    
                    Spacer()
                }
                
                VStack {
                    Spacer()
                    
                    HStack {
                        Button("Clear All") {
                            showingClearAlert = true
                        }
                        .foregroundColor(.red)
                        
                        Spacer()

                        Text("Database: \(databaseSize)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(.ultraThinMaterial, in: Rectangle())
                }
            }
            .frame(minWidth: 320)
            
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
                updateDatabaseSize()
            }
        } message: {
            Text("This will permanently delete all song history. This action cannot be undone.")
        }
        .onAppear {
            if selectedEntry == nil && !historyInteractor.recentHistory.isEmpty {
                selectedEntry = historyInteractor.recentHistory.first
            }
            updateDatabaseSize()
        }
        .onChange(of: historyInteractor.recentHistory) { _, newHistory in
            if let selected = selectedEntry,
               !newHistory.contains(where: { $0.id == selected.id }) {
                selectedEntry = newHistory.first
            } else if selectedEntry == nil && !newHistory.isEmpty {
                selectedEntry = newHistory.first
            }
            updateDatabaseSize()
        }
    }
    
    private func isCurrentlyPlaying(_ entry: SongHistory) -> Bool {
        guard let currentTrack = musicInteractor.currentTrack,
              musicInteractor.currentState == .playing else { return false }
        
        let isSameTrack = entry.trackId == currentTrack.id && 
                         entry.artist == currentTrack.artist &&
                         entry.trackName == currentTrack.name
        
        guard isSameTrack else { return false }
        
        let mostRecentEntry = historyInteractor.recentHistory
            .filter { $0.trackId == currentTrack.id && $0.artist == currentTrack.artist && $0.trackName == currentTrack.name }
            .max(by: { $0.playedAt < $1.playedAt })
        
        return entry.id == mostRecentEntry?.id
    }
    
    private func updateDatabaseSize() {
        Task {
            let size = historyInteractor.getDatabaseSize()
            await MainActor.run {
                databaseSize = size
            }
        }
    }
}
