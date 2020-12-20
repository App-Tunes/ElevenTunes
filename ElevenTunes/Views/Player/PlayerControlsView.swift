//
//  PlayerControlsView.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 19.12.20.
//

import SwiftUI

struct PlayerControlsView: View {
    @State var player: Player
    @State var playing: Track?
    @State var isPlaying: Bool = false

    var body: some View {
        HStack {
            Text(playing?[.ttitle] ?? "Nothing Playing")
            
            Button(action: {
                player.toggle()
            }) {
                if isPlaying {
                    Image(systemName: "pause.fill")
                }
                else {
                    Image(systemName: "play.fill")
                }
            }
                .buttonStyle(BorderlessButtonStyle())
                .keyboardShortcut(.space, modifiers: [])
        }
        .onReceive(player.$playing) { track in
            self.playing = track
        }
        .onReceive(player.$state) { state in
            self.isPlaying = state.isPlaying
        }
        .frame(minWidth: 500)
        .frame(height: 50)
    }
}

struct PlayerControlsView_Previews: PreviewProvider {
    static var previews: some View {
        let player = Player()
        
        PlayerControlsView(player: player)
    }
}
