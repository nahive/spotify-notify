import SwiftUI

// MARK: - AlbumArtworkView
struct AlbumArtworkView: View {
    let track: MusicTrack
    
    var body: some View {
        Group {
            if let artwork = track.artwork {
                switch artwork {
                case .url(let url):
                    AsyncImage(url: url) { phase in
                        CoverImageView(image: phase.image ?? Image("IconSettings"), album: track.album)
                    }
                    .albumArtworkModifier()
                    .accessibilityLabel("Album artwork for \(track.album ?? track.name)")
                    
                case .image(let image):
                    CoverImageView(image: Image(nsImage: image), album: track.album)
                    .albumArtworkModifier()
                    .accessibilityLabel("Album artwork for \(track.album ?? track.name)")
                }
            }
        }
    }
}

// MARK: - View Extensions
private extension View {
    func albumArtworkModifier() -> some View {
        self
            .padding(8)
            .frame(width: 100, height: 100)
            .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
    }
} 