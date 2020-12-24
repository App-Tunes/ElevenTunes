//
//  PreferencesView.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 23.12.20.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.spotify) var spotify: Spotify?
    
    enum Tabs: Hashable {
        case general, spotify
    }
    
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tag(Tabs.general)
            
            if let spotify = spotify {
                SpotifySettingsView(spotify: spotify)
                    .tag(Tabs.spotify)
            }
        }
        .padding(20)
        .frame(width: 500)
    }
}
