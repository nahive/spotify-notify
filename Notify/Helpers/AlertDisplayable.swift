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
        
        let response = alert.runModal()
        switch response {
        case .alertFirstButtonReturn:
            onSettingsTap()
        default:
            break
        }
    }
}
