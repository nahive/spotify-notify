import AppKit
import Combine
import QuartzCore
import SwiftUI

@available(macOS 26.0, *)
@MainActor
final class NotchWindowController {
    private let panel: NSPanel
    private let viewModel: NotchViewModel
    private var cancellables: Set<AnyCancellable> = []

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

        viewModel.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.layout() }
            .store(in: &cancellables)

        viewModel.$metrics
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.layout() }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: NSApplication.didChangeScreenParametersNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.viewModel.refreshScreen()
                self?.layout()
            }
            .store(in: &cancellables)

        layout()
        panel.orderFrontRegardless()
    }

    func close() {
        cancellables.removeAll()
        panel.close()
    }

    private func layout() {
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
