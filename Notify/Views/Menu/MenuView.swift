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
    
    var body: some View {
        PlayerView(musicInteractor: musicInteractor, track: musicInteractor.currentTrack)
            .frame(width: 480)
            .padding()
            .overlay(alignment: .topTrailing) {
                Menu {
                    if let selectedApplication = defaultsInteractor.selectedApplication {
                        Button {
                            musicInteractor.openApplication()
                        } label: {
                            Text("Open \(selectedApplication.appName)")
                            Image(systemName: "play.house")
                        }
                        Divider()
                    }
                    Button {
                        openWindow(id: "history")
                        NSApp.activate(ignoringOtherApps: true)
                    } label: {
                        Text("Song History")
                        Image(systemName: "clock")
                    }
                    Button {
                        openSettings()
                        NSApp.activate(ignoringOtherApps: true)
                    } label: {
                        Text("Settings")
                        Image(systemName: "gear")
                    }
                    Button {
                        NSApp.terminate(nil)
                    } label: {
                        Text("Quit")
                        Image(systemName: "power")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                }
                .menuIndicator(.hidden)
                .menuStyle(.borderlessButton)
                .accessibilityLabel("More options")
                .frame(width: 25, height: 20)
                .padding()
            }
    }
}

