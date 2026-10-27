import Foundation
import AppKit

@MainActor
protocol AlertDisplayable {
    func showSettingsAlert(message: LocalizedStringResource, onSettingsTap: () -> Void)
}

extension AlertDisplayable {
    func showSettingsAlert(message: LocalizedStringResource, onSettingsTap: () -> Void) {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = String(localized: message)
        alert.addButton(withTitle: String(localized: "Go to Settings"))
        alert.addButton(withTitle: String(localized: "Cancel"))
        
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
