import SwiftUI

struct NotchView: View {
    let viewModel: NotchViewModel

    private var notch: NotchInteractor { viewModel.notch }

    private var accent: Color {
        notch.track?.accentColor ?? NowPlaying.fallbackAccent
    }

    private var shape: NotchShape {
        let hasNotch = viewModel.metrics.hasNotch
        return switch viewModel.state {
        case .expanded:
            // Same swoosh language as the pill — stretched top flares flowing
            // into straight walls — but tighter bottom corners, so the tall
            // card reads grounded rather than melting at its base.
            NotchShape(
                topRadius: 12,
                topSpread: 20,
                bottomRadius: hasNotch ? 16 : 20,
                bottomSpread: hasNotch ? 26 : 32
            )
        case .pill:
            // The corners consume the pill's full height (bottomRadius clamps
            // to it), so NotchShape draws each side as one long shallow sweep.
            NotchShape(
                topRadius: 10,
                topSpread: hasNotch ? 24 : 26,
                bottomRadius: viewModel.pillRowHeight,
                bottomSpread: hasNotch ? 34 : 48
            )
        default:
            NotchShape(topRadius: 10, topSpread: 10, bottomRadius: hasNotch ? 13 : 20, bottomSpread: hasNotch ? 22 : 44)
        }
    }

    var body: some View {
        // The view fills the window, which the controller sizes and animates.
        // Content is driven off the window's live bounds (see `content`), so the
        // panel's frame animation is the single source of truth for size and the
        // pill grows in lockstep instead of animating separately and jumping.
        ZStack(alignment: .top) {
            background
            content
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .contentShape(Rectangle())
        .onHover { viewModel.hoverChanged($0) }
        // Only cosmetic, state-driven properties animate here (shape corner
        // radius, card fade); size comes from the window, not from this.
        .animation(.easeInOut(duration: 0.35), value: viewModel.state)
        .environment(\.colorScheme, .dark)
    }

    @ViewBuilder
    private var content: some View {
        let expanded = viewModel.state == .expanded

        switch viewModel.state {
        case .pill, .expanded:
            GeometryReader { geo in
                ZStack(alignment: .top) {
                    // Collapsed pill: minimal title + equalizer, pinned to the
                    // top. Fades out as the panel opens.
                    collapsedRow
                        .frame(height: viewModel.pillRowHeight)
                        .opacity(expanded ? 0 : 1)
                    // Full detail card, forced to the window's live height so its
                    // large intrinsic size can't stretch the layout (which would
                    // clip the shape into a square). Content sits at the top
                    // (artwork + title), controls at the bottom; as the panel
                    // grows it's revealed top-down by the clip and fades in.
                    ExpandedCard(notch: notch)
                        .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
                        .opacity(expanded ? 1 : 0)
                        .clipped()
                }
            }
            .clipShape(shape)
        case .hidden, .shape:
            EmptyView()
        }
    }

    @ViewBuilder
    private var collapsedRow: some View {
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
