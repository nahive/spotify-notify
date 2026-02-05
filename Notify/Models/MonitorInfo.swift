import AppKit

struct MonitorInfo: Identifiable, Hashable {
    let id: String
    let name: String
    let isMain: Bool

    init(from screen: NSScreen) {
        self.id = screen.localizedName
        self.name = screen.localizedName
        self.isMain = screen == NSScreen.main
    }

    static var allConnected: [MonitorInfo] {
        NSScreen.screens.map { MonitorInfo(from: $0) }
    }

    static var mainMonitor: MonitorInfo? {
        guard let main = NSScreen.main else { return nil }
        return MonitorInfo(from: main)
    }
}
