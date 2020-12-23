//
//  PreferencesView.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 23.12.20.
//

import SwiftUI

struct SettingsView: View {
    enum Tabs: Hashable {
        case general, spotify
    }
    
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tag(Tabs.general)
            SpotifySettingsView()
                .tag(Tabs.spotify)
        }
        .padding(20)
        .frame(width: 500)
    }
}
