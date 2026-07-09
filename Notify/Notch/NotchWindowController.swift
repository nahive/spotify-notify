import AppKit
import Combine
import SwiftUI

@available(macOS 26.0, *)
@MainActor
final class NotchWindowController {
    private let panel: NSPanel
    private let viewModel: NotchViewModel
    private var cancellables: Set<AnyCancellable> = []
    private var lastSize: CGSize = .zero

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

        let shrinking = size.width < lastSize.width || size.height < lastSize.height
        lastSize = size

        if shrinking {
            // Let the SwiftUI collapse animation finish before clipping the window.
            Task { @MainActor [weak self] in
                try? await Task.sleep(for: .milliseconds(400))
                guard let self, self.viewModel.windowSize == size else { return }
                self.panel.setFrame(frame, display: true)
            }
        } else {
            panel.setFrame(frame, display: true)
        }
    }
}
