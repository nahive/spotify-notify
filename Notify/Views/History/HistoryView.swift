import SwiftUI
import AppKit

struct HistoryView: View {
    @EnvironmentObject var historyInteractor: HistoryInteractor
    @EnvironmentObject var musicInteractor: MusicInteractor
    @State private var showingClearAlert = false
    @State private var selectedEntry: SongHistory?
    
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
                                    selectedEntry = entry
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
                        .onChange(of: historyInteractor.recentHistory) { _, newHistory in
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
            if selectedEntry == nil && !historyInteractor.recentHistory.isEmpty {
                selectedEntry = historyInteractor.recentHistory.first
            }
        }
        .onChange(of: historyInteractor.recentHistory) { _, newHistory in
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
        
        let isSameTrack = entry.trackId == currentTrack.id && 
                         entry.artist == currentTrack.artist &&
                         entry.trackName == currentTrack.name
        
        guard isSameTrack else { return false }
        
        let mostRecentEntry = historyInteractor.recentHistory
            .filter { $0.trackId == currentTrack.id && $0.artist == currentTrack.artist && $0.trackName == currentTrack.name }
            .max(by: { $0.playedAt < $1.playedAt })
        
        return entry.id == mostRecentEntry?.id
    }
}
