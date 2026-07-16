import AppKit
import Observation
import SwiftUI

enum NotchDisplayState: Equatable {
    /// Nothing rendered; the window still senses hover over the notch area.
    case hidden
    /// Just the black notch shape (invisible on a real notch).
    case shape
    /// The minimal pill: track text beside the notch and an equalizer.
    case pill
    /// The minimal pill with a card of artwork + controls slid out beneath it.
    case expanded
}

@MainActor
@Observable
final class NotchViewModel {
    private(set) var state: NotchDisplayState = .shape
    private(set) var metrics: NotchMetrics

    let notch: NotchInteractor
    let defaults: DefaultsInteractor

    @ObservationIgnored private var hovering = false
    @ObservationIgnored private var collapseTask: Task<Void, Never>?
    @ObservationIgnored private var observationTask: Task<Void, Never>?

    /// Width of each track-text wing beside a physical notch.
    private static let wingWidth: CGFloat = 156
    /// Pill width on screens without a physical notch.
    private static let syntheticWidth: CGFloat = 340
    /// Pill-row height on screens without a physical notch.
    private static let syntheticPillHeight: CGFloat = 34
    /// Height of the expanded detail card revealed on hover. Fits two rows:
    /// artwork/track detail on top, playback controls beneath.
    static let cardHeight: CGFloat = 118

    init(notch: NotchInteractor, defaults: DefaultsInteractor) {
        self.notch = notch
        self.defaults = defaults
        self.metrics = NotchGeometry.pickScreen(preferred: defaults.notchPreferredScreen)
            .map(NotchGeometry.metrics(for:)) ?? NotchGeometry.fallbackMetrics

        // Track presence plus the two settings this view model depends on;
        // reads inside the loop body are deliberately untracked.
        observationTask = Task { [weak self] in
            for await _ in Observations({ (notch.track == nil, defaults.notchVisibility, defaults.notchPreferredScreen) }) {
                guard let self else { return }
                self.refreshScreen()
                self.recompute()
            }
        }
    }

    deinit {
        observationTask?.cancel()
        collapseTask?.cancel()
    }

    // MARK: - Inputs

    func hoverChanged(_ isHovering: Bool) {
        if isHovering {
            collapseTask?.cancel()
            collapseTask = nil
            hovering = true
            recompute()
        } else {
            collapseTask?.cancel()
            collapseTask = Task { [weak self] in
                try? await Task.sleep(for: .milliseconds(220))
                guard !Task.isCancelled, let self else { return }
                self.hovering = false
                self.recompute()
            }
        }
    }

    func refreshScreen() {
        guard let screen = NotchGeometry.pickScreen(preferred: defaults.notchPreferredScreen) else { return }
        let updated = NotchGeometry.metrics(for: screen)
        if updated != metrics {
            metrics = updated
        }
    }

    // MARK: - State

    private func recompute() {
        let track = notch.track

        let base: NotchDisplayState
        switch defaults.notchVisibility {
        case .off, .always:
            // .off never reaches here (the window is destroyed); treat it like .always defensively.
            base = track == nil ? .shape : .pill
        case .whilePlaying:
            base = track == nil ? (metrics.hasNotch ? .shape : .hidden) : .pill
        case .onHover:
            base = metrics.hasNotch ? .shape : .hidden
        }

        var next = base
        if hovering, track != nil {
            next = .expanded
        }

        if next != state {
            state = next
        }
    }

    // MARK: - Sizing

    /// Height of the minimal pill row. The expanded card grows below it, so this
    /// stays fixed whether collapsed or expanded — only the total height changes.
    var pillRowHeight: CGFloat {
        metrics.hasNotch ? metrics.notchSize.height : Self.syntheticPillHeight
    }

    var contentSize: CGSize {
        let notchSize = metrics.notchSize
        // Pill width is constant between .pill and .expanded so hover only slides
        // the card down — the top row never reflows.
        let width = metrics.hasNotch ? notchSize.width + 2 * Self.wingWidth : Self.syntheticWidth
        switch state {
        case .hidden, .shape:
            return notchSize
        case .pill:
            return CGSize(width: width, height: pillRowHeight)
        case .expanded:
            // The expanded panel is the detail card alone — no separate pill row
            // above it — so the artwork/title sit right at the top.
            return CGSize(width: width, height: Self.cardHeight)
        }
    }

    /// The window is sized to exactly the content: the SwiftUI view fills it and
    /// the shape draws to its edges. Keeping them equal makes the panel's own
    /// frame animation the single source of truth for size, so the content grows
    /// in perfect lockstep instead of animating separately and jumping.
    var windowSize: CGSize { contentSize }
}
