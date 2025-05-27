//
//  SettingsView.swift
//  SpotifyNotify
//
//  Created by Szymon Maślanka on 2023/06/11.
//  Copyright © 2023 Szymon Maślanka. All rights reserved.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var defaultsInteractor: DefaultsInteractor
    @EnvironmentObject var musicInteractor: MusicInteractor
    @EnvironmentObject var notificationsInteractor: NotificationsInteractor
    
    var body: some View {
        TabView {
            GeneralSettingsView(defaultsInteractor: defaultsInteractor,
                                musicInteractor: musicInteractor,
                                notificationsInteractor: notificationsInteractor)
                .padding()
                .tabItem {
                    Label("General", systemImage: "gear")
                }
            
            NotificationSettingsView(defaultsInteractor: defaultsInteractor,
                                     notificationsInteractor: notificationsInteractor)
                .padding()
                .tabItem {
                    Label("Notifications", systemImage: "bell.badge")
                }
            
            AboutSettingsView()
                .padding()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .frame(maxWidth: 450)
        .tabViewStyle(.automatic)
    }
}

struct Settings_Preview: PreviewProvider {
    @StateObject private static var defaultsInteractor = DefaultsInteractor()
    
    static var previews: some View {
        SettingsView()
            .environmentObject(defaultsInteractor)
    }
}
