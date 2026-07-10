import AppKit
import Combine
import SwiftUI

@available(macOS 26.0, *)
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

@available(macOS 26.0, *)
@MainActor
final class NotchViewModel: ObservableObject {
    @Published private(set) var state: NotchDisplayState = .shape
    @Published private(set) var metrics: NotchMetrics

    let notch: NotchInteractor
    let defaults: DefaultsInteractor

    private var hovering = false
    private var collapseTask: Task<Void, Never>?
    private var cancellables: Set<AnyCancellable> = []

    static let glowPadding: CGFloat = 14
    /// Width of each track-text wing beside a physical notch.
    private static let wingWidth: CGFloat = 140
    /// Pill width on screens without a physical notch.
    private static let syntheticWidth: CGFloat = 340
    /// Pill-row height on screens without a physical notch.
    private static let syntheticPillHeight: CGFloat = 34
    /// Height of the artwork + controls card revealed on hover.
    static let cardHeight: CGFloat = 82

    init(notch: NotchInteractor, defaults: DefaultsInteractor) {
        self.notch = notch
        self.defaults = defaults
        self.metrics = NotchGeometry.metrics(for: NotchGeometry.pickScreen(preferred: defaults.notchPreferredScreen) ?? NSScreen.screens[0])

        notch.$track
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.recompute() }
            .store(in: &cancellables)

        defaults.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.refreshScreen()
                self?.recompute()
            }
            .store(in: &cancellables)
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
        // Debug hook: NOTIFY_NOTCH_FORCE_STATE=pill|inline pins the UI to one state.
        if let forced = Self.forcedState {
            if forced != state { state = forced }
            return
        }

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

    private static let forcedState: NotchDisplayState? = {
        switch ProcessInfo.processInfo.environment["NOTIFY_NOTCH_FORCE_STATE"] {
        case "pill": .pill
        case "inline", "expanded": .expanded
        default: nil
        }
    }()

    // MARK: - Sizing

    /// Height of the minimal pill row. The expanded card grows below it, so this
    /// stays fixed whether collapsed or expanded — only the total height changes.
    var pillRowHeight: CGFloat {
        metrics.hasNotch ? metrics.notchSize.height : Self.syntheticPillHeight
    }

    var cardHeight: CGFloat { Self.cardHeight }

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
            return CGSize(width: width, height: pillRowHeight + Self.cardHeight)
        }
    }

    var windowSize: CGSize {
        // Window is sized to the largest content this state can show, plus room
        // for effects to spill without clipping.
        let content = contentSize
        return CGSize(
            width: content.width + 2 * Self.glowPadding,
            height: content.height + Self.glowPadding * 1.6
        )
    }
}
