import SwiftUI
import AppKit

// MARK: - MenuView
struct MenuView: View {
    @Environment(\.openWindow) private var openWindow
    @Environment(\.openSettings) private var openSettings
    
    @Environment(MusicInteractor.self) var musicInteractor
    @Environment(NotificationsInteractor.self) var notificationsInteractor
    @Environment(DefaultsInteractor.self) var defaultsInteractor
    @Environment(HistoryInteractor.self) var historyInteractor
    @Environment(NotchInteractor.self) var notchInteractor

    /// Accent extracted from the artwork (the notch pill computes it anyway);
    /// nil with nothing playing so the menu falls back to plain material.
    private var accent: Color? {
        notchInteractor.track.map(\.accentColor)
    }

    var body: some View {
        PlayerView(musicInteractor: musicInteractor, track: musicInteractor.currentTrack)
            .frame(width: PlayingView.width)
            .padding(16)
            .background {
                // A soft wash from the top only: the panel's own material
                // stays the surface, the artwork colour just warms it.
                if let accent {
                    LinearGradient(
                        colors: [accent.opacity(0.3), accent.opacity(0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea()
                    .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.6), value: accent)
            .onAppear {
                // Shuffle, repeat and volume change without any notification.
                musicInteractor.refreshPlaybackOptions()
            }
            .overlay(alignment: .topTrailing) {
                Menu {
                    if let application = musicInteractor.currentApplication {
                        // `Label`, not Text + Image: SwiftUI's AppKit menu
                        // renderer drops a sibling Image and only bridges Label
                        // to NSMenuItem.image.
                        Button {
                            musicInteractor.openApplication()
                        } label: {
                            Label("Open \(application.appName)", systemImage: "play.house")
                        }
                        Divider()
                    }
                    Button {
                        AppWindow.showHistory(using: openWindow)
                    } label: {
                        Label("Song History", systemImage: "clock")
                    }
                    Button {
                        AppWindow.showSettings(using: openSettings)
                    } label: {
                        Label("Settings", systemImage: "gear")
                    }
                    .keyboardShortcut(",")
                    Button {
                        NSApp.terminate(nil)
                    } label: {
                        Label("Quit", systemImage: "power")
                    }
                    .keyboardShortcut("q")
                } label: {
                    Image(systemName: "ellipsis")
                }
                .menuIndicator(.hidden)
                .menuStyle(.borderlessButton)
                .accessibilityLabel("More options")
                .frame(width: 28, height: 28)
                .contentShape(Rectangle())
                .padding(8)
            }
    }
}

