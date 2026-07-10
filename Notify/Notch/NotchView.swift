import SwiftUI

@available(macOS 26.0, *)
struct NotchView: View {
    @ObservedObject var viewModel: NotchViewModel
    @ObservedObject private var notch: NotchInteractor
    @Namespace private var glassNamespace

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

    /// Liquid Glass material for the pill. The glass refracts and lenses the
    /// desktop behind it; the darkness comes from a black *tint on the glass*
    /// (not an opaque fill over it) so the refraction stays visible, and
    /// `.interactive()` lets the material respond to the pointer. On a physical
    /// notch the camera strip stays opaque black so it blends with the real bezel.
    private var background: some View {
        let metrics = viewModel.metrics
        let state = viewModel.state
        let visible = state != .hidden

        // `.clear` lenses (sharp refraction) rather than frosts; the darkness is
        // a black tint on the glass so the refraction stays visible. Darker on a
        // physical notch so the wings blend toward the black bezel.
        let tint = metrics.hasNotch ? 0.62 : 0.5
        let glass: Glass = .clear.tint(.black.opacity(tint)).interactive()

        return ZStack(alignment: .top) {
            // The container gives the glass a shared sampling region, so the
            // pill morphs like liquid as it extends/collapses instead of just
            // resizing.
            GlassEffectContainer(spacing: 24) {
                shape
                    .fill(.black.opacity(0.001))
                    .glassEffect(glass, in: shape)
                    .glassEffectID("pill", in: glassNamespace)
            }
            // Hidden entirely when empty; the black core alone covers the
            // physical notch in the `.shape` state.
            .opacity(visible && state != .shape ? 1 : 0)

            if metrics.hasNotch, visible {
                Rectangle()
                    .fill(.black)
                    .frame(width: metrics.notchSize.width, height: metrics.notchSize.height)
            }
        }
    }
}
