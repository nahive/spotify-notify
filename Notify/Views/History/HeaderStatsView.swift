import SwiftUI

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