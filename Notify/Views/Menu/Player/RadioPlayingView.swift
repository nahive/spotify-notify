import SwiftUI

struct RadioPlayingView: View {
    let musicInteractor: MusicInteractor
    
    @State private var animationTrigger = false
    
    var body: some View {
        VStack(spacing: 16) {
            radioWavesView
            titleView
            descriptionView
            controlButtonsView
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 30)
        .frame(maxWidth: 280)
        .frame(maxWidth: .infinity)
        .onAppear {
            animationTrigger = true
        }
    }
    
    private var radioWavesView: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { index in
                radioWaveBar(index: index)
            }
        }
        .padding(.bottom, 8)
    }
    
    private func radioWaveBar(index: Int) -> some View {
        let baseHeight: CGFloat = 20
        let animationDelay = Double(index) * 0.2
        let scaleFactors: [CGFloat] = [0.4, 0.8, 0.6]
        
        return RoundedRectangle(cornerRadius: 2)
            .fill(Color.primary.gradient)
            .frame(width: 4, height: baseHeight)
            .scaleEffect(y: animationTrigger ? 1.0 : scaleFactors[index], anchor: .bottom)
            .animation(
                .easeInOut(duration: 0.8)
                .repeatForever(autoreverses: true)
                .delay(animationDelay),
                value: animationTrigger
            )
    }
    
    private var titleView: some View {
        Text("Radio Playing")
            .font(.title2)
            .fontWeight(.semibold)
            .foregroundStyle(.primary)
    }
    
    private var descriptionView: some View {
        Text("Apple Music radio is playing but track details aren't available")
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .lineLimit(nil)
    }
    
    private var controlButtonsView: some View {
        HStack(spacing: 12) {
            PlayerControlButton(
                systemName: "backward.fill",
                font: .title3,
                accessibilityLabel: "Previous track",
                action: musicInteractor.previousTrack
            )
            PlayerControlButton(
                systemName: musicInteractor.currentState == .playing ? "pause.fill" : "play.fill",
                font: .title2,
                accessibilityLabel: musicInteractor.currentState == .playing ? "Pause" : "Play",
                action: musicInteractor.playPause
            )
            PlayerControlButton(
                systemName: "forward.fill",
                font: .title3,
                accessibilityLabel: "Next track",
                action: musicInteractor.nextTrack
            )
        }
    }
} 
