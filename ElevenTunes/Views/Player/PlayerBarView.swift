//
//  PlayerBarView.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 15.12.20.
//

import SwiftUI

struct PlayerBarView: View {
    @Environment(\.player) private var player: Player!

    var body: some View {
        VStack {
            HStack {
                PlayerControlsView(player: player)
            }
                .layoutPriority(2)
            
            ZStack {
                PlayPositionView(player: player.singlePlayer)
            }
            .background(LinearGradient(gradient: Gradient(colors: [Color.black.opacity(0.3), .clear]), startPoint: .bottom, endPoint: .top))
        }
    }
}

struct PlayerBarView_Previews: PreviewProvider {
    static var previews: some View {
        PlayerBarView()
    }
}
