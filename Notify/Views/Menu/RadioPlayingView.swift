//
//  RadioPlayingView.swift
//  Notify
//
//  Created by Szymon Maślanka on 2025/01/23.
//  Copyright © 2025 Szymon Maślanka. All rights reserved.
//

import SwiftUI

struct RadioPlayingView: View {
    let musicInteractor: MusicInteractor
    
    @State private var isHovering = false
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
        .onAppear {
            startAnimations()
        }
    }
    
    private func startAnimations() {
        // Start radio wave animation immediately
        animationTrigger = true
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
        let scaleFactors: [CGFloat] = [0.4, 0.8, 0.6] // Different heights for each bar
        
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
            previousButton
            playPauseButton
            nextButton
        }
    }
    
    private var previousButton: some View {
        Button(action: {
            musicInteractor.previousTrack()
        }) {
            controlButtonContent(systemName: "backward.fill", size: .title3, padding: 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var playPauseButton: some View {
        let iconName = musicInteractor.currentState == .playing ? "pause.fill" : "play.fill"
        let buttonBackground = Circle()
            .fill(.primary.opacity(isHovering ? 0.15 : 0.08))
            .stroke(.primary.opacity(0.2), lineWidth: 1)
        
        return Button(action: {
            musicInteractor.playPause()
        }) {
            Image(systemName: iconName)
                .font(.title2)
                .foregroundStyle(.primary)
                .padding(12)
                .background(buttonBackground)
                .scaleEffect(isHovering ? 1.05 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovering = hovering
            }
        }
    }
    
    private var nextButton: some View {
        Button(action: {
            musicInteractor.nextTrack()
        }) {
            controlButtonContent(systemName: "forward.fill", size: .title3, padding: 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func controlButtonContent(systemName: String, size: Font, padding: CGFloat) -> some View {
        let buttonBackground = Circle()
            .fill(.primary.opacity(0.1))
            .stroke(.primary.opacity(0.2), lineWidth: 1)
        
        return Image(systemName: systemName)
            .font(size)
            .foregroundStyle(.primary)
            .padding(padding)
            .background(buttonBackground)
    }
} 
