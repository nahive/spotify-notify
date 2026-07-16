import AppKit

struct NotchMetrics: Equatable, Sendable {
    var screenFrame: NSRect
    var hasNotch: Bool
    var notchSize: CGSize
    var menuBarHeight: CGFloat
}

@MainActor
enum NotchGeometry {
    static let syntheticNotchWidth: CGFloat = 190

    static var fallbackMetrics: NotchMetrics {
        NotchMetrics(
            screenFrame: .zero,
            hasNotch: false,
            notchSize: CGSize(width: syntheticNotchWidth, height: 32),
            menuBarHeight: 24
        )
    }

    static func metrics(for screen: NSScreen) -> NotchMetrics {
        let topInset = screen.safeAreaInsets.top
        let menuBarHeight = max(screen.frame.maxY - screen.visibleFrame.maxY, 24)

        if topInset > 0 {
            let left = screen.auxiliaryTopLeftArea?.width ?? 0
            let right = screen.auxiliaryTopRightArea?.width ?? 0
            let width = screen.frame.width - left - right
            return NotchMetrics(
                screenFrame: screen.frame,
                hasNotch: true,
                notchSize: CGSize(width: width, height: topInset),
                menuBarHeight: menuBarHeight
            )
        }

        // A synthetic notch slightly taller than the menu bar reads better as a pill.
        return NotchMetrics(
            screenFrame: screen.frame,
            hasNotch: false,
            notchSize: CGSize(width: syntheticNotchWidth, height: max(menuBarHeight, 32)),
            menuBarHeight: menuBarHeight
        )
    }

    static func pickScreen(preferred: String) -> NSScreen? {
        let screens = NSScreen.screens
        guard !screens.isEmpty else { return nil }

        if preferred != DefaultsInteractor.automaticScreen,
           let match = screens.first(where: { $0.localizedName == preferred }) {
            return match
        }

        return screens.first(where: { $0.safeAreaInsets.top > 0 }) ?? NSScreen.main ?? screens.first
    }
}
