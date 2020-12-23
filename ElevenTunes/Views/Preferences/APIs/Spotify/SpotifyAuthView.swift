//
//  SpotifyAuthView.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 23.12.20.
//

import SwiftUI

struct SpotifyAuthView: View {
    @Environment(\.spotify) private var spotify: Spotify
    @State var isAuthorized = false
    @State var isLoading = false

    var body: some View {
        Section(header: Text("Authentication")) {
            HStack {
                Button(action: {
                    spotify.authenticator.authorize()
                }) {
                    Text("Authorize Spotify")
                }.disabled(isAuthorized)
                
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(0.5, anchor: .center)
                }
                else {
                    Image(systemName: "circle.fill")
                        .foregroundColor(isAuthorized ? .green : .red)
                }
            }
        }
        .onReceive(spotify.authenticator.$isAuthorized) { isAuthorized in
            self.isAuthorized = isAuthorized
        }
        .onReceive(spotify.authenticator.$isRetrievingTokens) { isRetrievingTokens in
            self.isLoading = isRetrievingTokens
        }
    }
}

struct SpotifyAuthView_Previews: PreviewProvider {
    static var previews: some View {
        SpotifyAuthView()
    }
}
