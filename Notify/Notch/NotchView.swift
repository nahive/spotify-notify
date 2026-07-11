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
        // Size comes from the window bounds, which the controller animates. The
        // content just fills them (inset by the glow margin) so it extends in
        // lockstep with the window instead of the window snapping ahead of it.
        ZStack(alignment: .top) {
            background
            content
        }
        .contentShape(Rectangle())
        .onHover { viewModel.hoverChanged($0) }
        .padding(EdgeInsets(
            top: 0,
            leading: NotchViewModel.glowPadding,
            bottom: NotchViewModel.glowPadding * 1.6,
            trailing: NotchViewModel.glowPadding
        ))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .animation(.smooth(duration: 0.35), value: viewModel.state)
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
                    .frame(height: viewModel.cardHeight)
                    .opacity(expanded ? 1 : 0)
                    // Tucked up behind the pill when collapsed; slides down into
                    // place as the panel opens.
                    .offset(y: expanded ? 0 : -18)
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
        let (glass, solid, gradient): (Double, Double, Double) = switch viewModel.state {
        case .hidden: (0, 0, 0)
        case .shape: (0, 1, 0)
        case .pill: metrics.hasNotch ? (0, 1, 0) : (1, 0.75, 0)
        case .expanded: (1, metrics.hasNotch ? 0.6 : 0.3, 0)
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
