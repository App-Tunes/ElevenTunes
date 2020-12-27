//
//  PreferencesView.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 23.12.20.
//

import SwiftUI

protocol SettingsLevel {
    var spotify: Spotify? { get }
}

struct SettingsLevelEnvironmentKey: EnvironmentKey {
    static let defaultValue: SettingsLevel? = nil
}

extension EnvironmentValues {
    var settingsLevel: SettingsLevel? {
        get { self[SettingsLevelEnvironmentKey] }
        set { self[SettingsLevelEnvironmentKey] = newValue }
    }
}

struct SettingsView: View {
    @Environment(\.settingsLevel) var settingsLevel: SettingsLevel!
    
    enum Tabs: Hashable {
        case general, spotify
    }
    
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tag(Tabs.general)
            
            if let spotify = settingsLevel.spotify {
                SpotifySettingsView(spotify: spotify)
                    .tag(Tabs.spotify)
            }
        }
        .padding(20)
        .frame(width: 500)
    }
}
