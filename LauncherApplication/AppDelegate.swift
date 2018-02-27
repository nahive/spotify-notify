//
//  AppDelegate.swift
//  LauncherApplication
//
//  Created by Szymon Maślanka on 27/02/2018.
//  Copyright © 2018 Szymon Maślanka. All rights reserved.
//

import Cocoa

extension Notification.Name {
	static let killLauncher = Notification.Name("kill.launcher.notification")
}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

	func applicationDidFinishLaunching(_ aNotification: Notification) {
		let isRunning = !NSWorkspace.shared.runningApplications
			.filter { $0.bundleIdentifier == AppConstants.bundleIdentifier }.isEmpty
		
		guard !isRunning else {
			terminate()
			return
		}
		
		let path = Bundle.main.bundlePath as NSString
		var components = path.pathComponents
		components.removeLast()
		components.removeLast()
		components.removeLast()
		components.append("MacOS")
		components.append("Notify")
		
		let newPath = NSString.path(withComponents: components)
		
		NSWorkspace.shared.launchApplication(newPath)
	}
	
	private func setupObservers() {
		let center = DistributedNotificationCenter.default()
		
		center.addObserver(self,  selector: #selector(terminate),
						   name: .killLauncher, object: AppConstants.bundleIdentifier)
	}
	
	@objc private func terminate() {
		NSApp.terminate(nil)
	}
}

private struct AppConstants {
	static let bundleIdentifier = "io.nahive.SpotifyNotify"
	static let launchIdentifier = "io.nahive.LauncherApplication"
}

