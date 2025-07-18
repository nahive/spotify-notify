import SwiftUI

struct NothingPlayingView: View {
    let musicInteractor: MusicInteractor
    
    @State private var isHovering = false
    
    private var isAppleMusic: Bool {
        musicInteractor.currentApplication?.bundleId == "com.apple.Music"
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Nothing Playing")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
            
            Text(isAppleMusic ? 
                "Start playing music in Apple Music to see controls" : 
                "Start playing music to see controls"
            )
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: {
                musicInteractor.playPause()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "play.fill")
                        .font(.title3)
                    Text(isAppleMusic ? "Open Apple Music" : "Play Music")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .foregroundStyle(.primary)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.primary.opacity(isHovering ? 0.15 : 0.08))
                        .stroke(.primary.opacity(0.2), lineWidth: 1)
                )
                .scaleEffect(isHovering ? 1.05 : 1.0)
            }
            .buttonStyle(PlainButtonStyle())
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.2)) {
                    isHovering = hovering
                }
            }
            .accessibilityLabel(isAppleMusic ? "Open Apple Music" : "Start playback")
            .accessibilityHint(isAppleMusic ? 
                "Double tap to open Apple Music" : 
                "Double tap to start playing music"
            )
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 30)
    }
} 
