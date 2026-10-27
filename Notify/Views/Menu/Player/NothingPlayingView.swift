import SwiftUI

/// Empty state for the menu. Distinguishes the four reasons nothing is playing
/// — no app chosen, automation denied, player not running, genuinely idle —
/// instead of always offering a play button that silently no-ops.
struct NothingPlayingView: View {
    let musicInteractor: MusicInteractor

    @Environment(\.openSettings) private var openSettings

    @State private var isHovering = false

    private enum Reason {
        case noAppSelected
        case automationDenied(SupportedMusicApplication)
        case playerClosed(SupportedMusicApplication)
        case idle
    }

    private var reason: Reason {
        guard let app = musicInteractor.currentApplication else { return .noAppSelected }
        switch musicInteractor.permissionStatus {
        case .denied: return .automationDenied(app)
        case .closed: return .playerClosed(app)
        case .granted: return .idle
        }
    }

    private var title: String {
        switch reason {
        case .noAppSelected: "No Music App Found"
        case .automationDenied: "Automation Access Needed"
        case .playerClosed(let app): "\(app.appName) Isn't Running"
        case .idle: "Nothing Playing"
        }
    }

    private var message: String {
        switch reason {
        case .noAppSelected:
            "Install Spotify or Apple Music, or pick one in Settings, to see what's playing."
        case .automationDenied(let app):
            "Notify needs permission to control \(app.appName) before it can read the current track."
        case .playerClosed(let app):
            "Open \(app.appName) and start playing to see controls."
        case .idle:
            "Start playing music to see controls."
        }
    }

    private var actionTitle: String {
        switch reason {
        case .noAppSelected: "Open Settings"
        case .automationDenied: "Grant Access"
        case .playerClosed(let app): "Open \(app.appName)"
        case .idle: "Play"
        }
    }

    private var actionIcon: String {
        switch reason {
        case .noAppSelected: "gear"
        case .automationDenied: "lock.open"
        case .playerClosed: "arrow.up.forward.app"
        case .idle: "play.fill"
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Button(action: performAction) {
                HStack(spacing: 8) {
                    Image(systemName: actionIcon)
                        .font(.title3)
                    Text(actionTitle)
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
            .buttonStyle(.plain)
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.2)) {
                    isHovering = hovering
                }
            }
            .accessibilityLabel(actionTitle)
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 30)
        .frame(maxWidth: .infinity)
    }

    private func performAction() {
        switch reason {
        case .noAppSelected:
            AppWindow.showSettings(using: openSettings)
        case .automationDenied(let app):
            musicInteractor.registerForAutomation(for: app)
        case .playerClosed:
            musicInteractor.openApplication()
        case .idle:
            musicInteractor.playPause()
        }
    }
}
