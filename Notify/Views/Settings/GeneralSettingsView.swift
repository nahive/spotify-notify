//
//  GeneralSettingsView.swift
//  Notify
//
//  Created by Szymon Maślanka on 2025/01/22.
//  Copyright © 2025 Szymon Maślanka. All rights reserved.
//

import SwiftUI
import Combine

struct GeneralSettingsView: View {
    let defaultsInteractor: DefaultsInteractor
    @StateObject var musicInteractor: MusicInteractor
    @StateObject var notificationsInteractor: NotificationsInteractor
    
    @State private var timerCancellable: AnyCancellable?
    
    var body: some View {
        VStack {
            musicAppSelectionView
                .padding(.bottom)
            
            notificationPermissionsView
            
            if let selectedApplication = defaultsInteractor.selectedApplication {
                controlPermissionsView(for: selectedApplication)
                    .frame(height: 20)
            }
        }
        .padding()
        .onChange(of: defaultsInteractor.selectedApplication) { _, new in
            musicInteractor.set(application: new)
        }
        .onAppear {
            startTimer()
        }
        .onDisappear {
            stopTimer()
        }
    }

    private var musicAppSelectionView: some View {
        HStack {
            ForEach(SupportedMusicApplication.allCases, id: \.rawValue) { app in
                ZStack {
                    if app.isInstalled {
                        if let icon = app.icon {
                            Image(nsImage: icon)
                                .resizable()
                                .frame(width: 80, height: 80)
                        } else {
                            Text(app.appName)
                                .frame(width: 80, height: 80)
                        }
                    } else {
                        Text(app.appName + " is not installed")
                            .frame(width: 80, height: 80)
                            .multilineTextAlignment(.center)
                    }
                }
                .background(defaultsInteractor.selectedApplication == app ? app.color.opacity(0.5) : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .onTapGesture {
                    guard app.isInstalled else { return }
                    defaultsInteractor.selectedApplication = app
                }
                .accessibilityLabel("Select \(app.appName)")
            }
        }
    }

    private var notificationPermissionsView: some View {
        VStack {
            HStack(alignment: .center) {
                Circle()
                    .foregroundStyle(notificationsInteractor.areNotificationsEnabled ? Color.green : Color.red)
                    .frame(width: 8)
                Text("Notification permissions")
            }
            if !notificationsInteractor.areNotificationsEnabled {
                Button("Enable notifications") {
                    notificationsInteractor.registerForNotifications()
                }
            }
        }
    }

    private func controlPermissionsView(for app: SupportedMusicApplication) -> some View {
        VStack {
            switch musicInteractor.permissionStatus {
            case .granted:
                HStack {
                    Circle()
                        .foregroundStyle(Color.green)
                        .frame(width: 8)
                    Text("Control permissions")
                }
            case .closed:
                Button("Open \(app.appName) to enable automation") {
                    musicInteractor.openApplication()
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.yellow)
            case .denied:
                Button("Enable control for \(app.appName)") {
                    musicInteractor.registerForAutomation(for: app)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.red)
            }
        }
    }

    private func startTimer() {
        timerCancellable = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                notificationsInteractor.updateNotificationsPermissions()
                musicInteractor.updateControlPermissions()
            }
    }

    private func stopTimer() {
        timerCancellable?.cancel()
    }
}

extension SupportedMusicApplication {
    var color: Color {
        switch self {
        case .applemusic:
            .appleMusic
        case .spotify:
            .spotify
        }
    }
    
    var icon: NSImage? {
        getAppIcon(for: bundleId)
    }
    
    private func getAppIcon(for bundleIdentifier: String) -> NSImage? {
        guard let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) else {
            return nil
        }

        return NSWorkspace.shared.icon(forFile: appURL.path)
    }
}
