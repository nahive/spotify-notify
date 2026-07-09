import SwiftUI

@available(macOS 26.0, *)
struct NotchView: View {
    @ObservedObject var viewModel: NotchViewModel
    @ObservedObject private var notch: NotchInteractor

    init(viewModel: NotchViewModel) {
        self.viewModel = viewModel
        self.notch = viewModel.notch
    }

    private var accent: Color {
        notch.track?.accentColor ?? NowPlaying.fallbackAccent
    }

    private var shape: NotchShape {
        let hasNotch = viewModel.metrics.hasNotch
        return switch viewModel.state {
        case .inline: NotchShape(topRadius: 10, bottomRadius: hasNotch ? 13 : 24)
        default: NotchShape(topRadius: 8, bottomRadius: hasNotch ? 13 : 14)
        }
    }

    var body: some View {
        let state = viewModel.state
        let size = viewModel.contentSize

        ZStack(alignment: .top) {
            background
            content
        }
        .frame(width: size.width, height: size.height)
        .contentShape(Rectangle())
        .onHover { viewModel.hoverChanged($0) }
        .animation(.smooth(duration: 0.35), value: state)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .environment(\.colorScheme, .dark)
    }

    @ViewBuilder
    private var content: some View {
        let state = viewModel.state
        let size = viewModel.contentSize
        let metrics = viewModel.metrics

        switch state {
        case .pill, .inline:
            Group {
                if metrics.hasNotch {
                    PillWings(
                        notch: notch,
                        metrics: metrics,
                        wingWidth: (size.width - metrics.notchSize.width) / 2,
                        inline: state == .inline,
                        accent: accent
                    )
                } else {
                    CenteredPill(notch: notch, inline: state == .inline, accent: accent)
                        .frame(width: size.width, height: size.height)
                }
            }
            .transition(.opacity)
        case .hidden, .shape:
            EmptyView()
        }
    }

    /// One persistent surface for every state. Layer opacities and shape radii
    /// animate, so state changes morph instead of cross-fading view trees.
    private var background: some View {
        let metrics = viewModel.metrics
        let (glass, solid, gradient): (Double, Double, Double) = switch viewModel.state {
        case .hidden: (0, 0, 0)
        case .shape: (0, 1, 0)
        case .pill: metrics.hasNotch ? (0, 1, 0) : (1, 0.75, 0)
        case .inline: (1, metrics.hasNotch ? 0.6 : 0.3, 0)
        }

        return ZStack {
            shape
                .fill(.black.opacity(0.01))
                .glassEffect(.regular, in: shape)
                .opacity(glass)
            shape
                .fill(.black)
                .opacity(solid)
            shape
                .fill(
                    LinearGradient(
                        colors: [.black.opacity(0.92), .black.opacity(0.6), .black.opacity(0.15)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .opacity(gradient)
        }
    }
}
