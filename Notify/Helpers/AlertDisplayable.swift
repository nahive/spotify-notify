import Foundation
import AppKit

@MainActor
protocol AlertDisplayable {
    func showSettingsAlert(message: String, onSettingsTap: () -> Void)
}

extension AlertDisplayable {
    func showSettingsAlert(message: String, onSettingsTap: () -> Void) {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = message
        alert.addButton(withTitle: "Go to Settings")
        alert.addButton(withTitle: "Cancel")
        
        // LSUIElement agents are not activated, so an unactivated modal can
        // appear behind the frontmost app while blocking all input.
        NSApp.activate()
        let response = alert.runModal()
        switch response {
        case .alertFirstButtonReturn:
            onSettingsTap()
        default:
            break
        }
    }
}
