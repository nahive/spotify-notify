import AppKit
import Combine
import SwiftUI

@available(macOS 26.0, *)
enum NotchDisplayState: Equatable {
    /// Nothing rendered; the window still senses hover over the notch area.
    case hidden
    /// Just the black notch shape (invisible on a real notch).
    case shape
    /// Artwork and equalizer wings beside the notch.
    case pill
    /// Pill plus playback controls.
    case inline
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
    private static let pillWing: CGFloat = 120
    private static let inlineWing: CGFloat = 170

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
        if hovering {
            next = .inline
        }

        if next != state {
            state = next
        }
    }

    private static let forcedState: NotchDisplayState? = {
        switch ProcessInfo.processInfo.environment["NOTIFY_NOTCH_FORCE_STATE"] {
        case "pill": .pill
        case "inline": .inline
        default: nil
        }
    }()

    // MARK: - Sizing

    var contentSize: CGSize {
        let notchSize = metrics.notchSize
        if metrics.hasNotch {
            switch state {
            case .hidden, .shape:
                return notchSize
            case .pill:
                return CGSize(width: notchSize.width + 2 * Self.pillWing, height: notchSize.height)
            case .inline:
                return CGSize(width: notchSize.width + 2 * Self.inlineWing, height: notchSize.height)
            }
        }
        switch state {
        case .hidden, .shape:
            return notchSize
        case .pill:
            return CGSize(width: 330, height: 32)
        case .inline:
            return CGSize(width: 450, height: 48)
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
