//
//  SpotifyAuthView.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 19.12.20.
//

import SwiftUI

struct SpotifySettingsView: View {
    @Environment(\.spotify) var spotify: Spotify
    
    var body: some View {
        Form {
            SpotifyAuthView()
                .padding(.bottom)
                        
            SpotifyDevicesView(devices: spotify.devices)
        }
        .padding(20)
        .frame(height: 300)
        .tabItem { Label {
                Text("Spotify")
            } icon: {
                Image("spotify-logo")
            }
        }
    }
}
