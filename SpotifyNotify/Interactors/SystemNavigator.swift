//
//  SystemNavigator.swift
//  SpotifyNotify
//
//  Created by Szymon Maślanka on 2025/01/17.
//  Copyright © 2025 Szymon Maślanka. All rights reserved.
//

import Foundation
import AppKit

final class SystemNavigator {
    static func openApplication(_ application: SupportedMusicApplication) {
        openApplication(bundleId: application.bundleId)
    }
    
    static func openApplication(bundleId: String) {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) else { return }

        let path = "/bin"
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.arguments = [path]
        NSWorkspace.shared.openApplication(at: url, configuration: configuration, completionHandler: nil)
    }
    
    static func openNotificationsSettings() {
        NSWorkspace.shared.open("x-apple.systempreferences:com.apple.preference.notifications".asURL!)
    }
    
    static func openAutomationSettings() {
        NSWorkspace.shared.open("x-apple.systempreferences:com.apple.preference.security?Privacy_Automation".asURL!)
    }
}
