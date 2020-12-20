//
//  PlayerBarView.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 15.12.20.
//

import SwiftUI

struct PlayerBarView: View {
    @Environment(\.player) private var player: Player

    var body: some View {
        VStack {
            HStack {
                PlayerControlsView(player: player)
                SpotifyAuthView()
            }
                .layoutPriority(2)
            
            PlayPositionView(player: player.soundPlayer)
        }
    }
}

struct PlayerBarView_Previews: PreviewProvider {
    static var previews: some View {
        PlayerBarView()
    }
}
