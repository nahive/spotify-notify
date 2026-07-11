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
        case .expanded: NotchShape(topRadius: 12, bottomRadius: hasNotch ? 16 : 28)
        default: NotchShape(topRadius: 10, bottomRadius: hasNotch ? 13 : 22)
        }
    }

    var body: some View {
        // The content is sized to the per-state contentSize so the background
        // shape draws at exactly the pill/expanded height (its rounded bottom
        // stays on-screen instead of being clipped off into a square). The
        // surrounding window is larger by the glow margin; the outer top-aligned
        // frame flushes the content to the top and leaves that margin to spill.
        let size = viewModel.contentSize
        ZStack(alignment: .top) {
            background
            content
        }
        .frame(width: size.width, height: size.height)
        .contentShape(Rectangle())
        .onHover { viewModel.hoverChanged($0) }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        // Same curve/duration as the window's own frame animation in
        // NotchWindowController.layout(), so the content grows in lockstep with
        // the panel instead of drifting apart and snapping (the expand "jump").
        .animation(.easeInOut(duration: 0.35), value: viewModel.state)
        .environment(\.colorScheme, .dark)
    }

    @ViewBuilder
    private var content: some View {
        let expanded = viewModel.state == .expanded

        switch viewModel.state {
        case .pill, .expanded:
            VStack(spacing: 0) {
                topRow
                    .frame(height: viewModel.pillRowHeight)
                ExpandedCard(notch: notch, accent: accent)
                    // Collapsed to zero height when not expanded so it takes no
                    // layout space — otherwise it inflates the stack past the
                    // pill height, pushing the title out of view and stretching
                    // the background shape until its rounded bottom clips into a
                    // square. Grows in as the panel opens.
                    .frame(height: expanded ? viewModel.cardHeight : 0)
                    .opacity(expanded ? 1 : 0)
                    .clipped()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .clipShape(shape)
        case .hidden, .shape:
            EmptyView()
        }
    }

    @ViewBuilder
    private var topRow: some View {
        let metrics = viewModel.metrics
        if metrics.hasNotch {
            PillWings(
                notch: notch,
                metrics: metrics,
                wingWidth: (viewModel.contentSize.width - metrics.notchSize.width) / 2,
                accent: accent
            )
        } else {
            CenteredPill(notch: notch, accent: accent)
        }
    }

    /// One persistent surface for every state. Layer opacities and shape radii
    /// animate, so state changes morph instead of cross-fading view trees.
    private var background: some View {
        let metrics = viewModel.metrics
        let (glass, solid): (Double, Double) = switch viewModel.state {
        case .hidden: (0, 0)
        case .shape: (0, 1)
        case .pill: metrics.hasNotch ? (0, 1) : (1, 0.82)
        case .expanded: (1, metrics.hasNotch ? 0.6 : 0.34)
        }

        // On a real notch the fill stays flat black so the wings blend into the
        // bezel; on a synthetic pill it fades top-to-bottom for a smoother,
        // less slab-like gradient that melts out of the screen edge.
        let bottom = solid * (metrics.hasNotch ? 1 : 0.55)

        return ZStack {
            shape
                .fill(.black.opacity(0.01))
                .glassEffect(.regular, in: shape)
                .opacity(glass)
            shape
                .fill(
                    LinearGradient(
                        colors: [.black.opacity(solid), .black.opacity(bottom)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        }
    }
}
