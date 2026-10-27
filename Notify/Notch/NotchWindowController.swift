import AppKit
import Observation
import QuartzCore
import SwiftUI

/// Owns the notch panel and its SwiftUI hosting view. Retained by
/// `NotchInteractor`; released only when `reconfigureNotchWindow()` calls
/// `close()` and then nils the reference. The `NotchInteractor` ⇄
/// `NotchViewModel` strong cycle is intentional (both are app-lifetime) and is
/// broken by that teardown path, so `close()` is the single safe teardown and
/// must stay idempotent.
@MainActor
final class NotchWindowController {
    private let panel: NSPanel
    private let viewModel: NotchViewModel
    private var layoutObservationTask: Task<Void, Never>?
    private var screenObserver: (any NSObjectProtocol)?
    private var isClosed = false

    init(viewModel: NotchViewModel) {
        self.viewModel = viewModel

        panel = NSPanel(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.hidesOnDeactivate = false
        panel.isMovable = false
        panel.isFloatingPanel = true
        // Must come after isFloatingPanel, which resets the level to .floating.
        panel.level = NSWindow.Level(rawValue: NSWindow.Level.mainMenu.rawValue + 3)
        panel.becomesKeyOnlyIfNeeded = true
        panel.isReleasedWhenClosed = false
        panel.animationBehavior = .none
        panel.acceptsMouseMovedEvents = true

        let hostingView = NSHostingView(rootView: NotchView(viewModel: viewModel))
        hostingView.sizingOptions = []
        panel.contentView = hostingView

        layoutObservationTask = Task { [weak self] in
            for await _ in Observations({ (viewModel.state, viewModel.metrics, viewModel.notch.track == nil) }) {
                guard let self else { return }
                self.layout()
            }
        }

        screenObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.viewModel.refreshScreen()
                self?.layout()
            }
        }

        layout()
        panel.orderFrontRegardless()
    }

    func close() {
        guard !isClosed else { return }
        isClosed = true
        layoutObservationTask?.cancel()
        layoutObservationTask = nil
        if let screenObserver {
            NotificationCenter.default.removeObserver(screenObserver)
        }
        screenObserver = nil
        panel.close()
    }

    private func layout() {
        // With no track, hover can never change state (see NotchViewModel.recompute),
        // so the panel must not eat clicks — in .hidden/.shape it is an invisible
        // 190x32 rectangle sitting on top of the menu bar.
        panel.ignoresMouseEvents = viewModel.notch.track == nil

        let size = viewModel.windowSize
        let screenFrame = viewModel.metrics.screenFrame
        let frame = NSRect(
            x: screenFrame.midX - size.width / 2,
            y: screenFrame.maxY - size.height,
            width: size.width,
            height: size.height
        )

        guard panel.frame != frame else { return }

        // On first layout, or when the pill jumps to a different screen (its
        // center moves), snap into place. State transitions keep the same center,
        // so they animate: the frame extends/collapses in lockstep with the
        // SwiftUI content that fills it.
        let recentred = abs(panel.frame.midX - frame.midX) > 50
        if panel.frame == .zero || recentred {
            panel.setFrame(frame, display: true)
            return
        }

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.35
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            context.allowsImplicitAnimation = true
            panel.animator().setFrame(frame, display: true)
        }
    }
}
