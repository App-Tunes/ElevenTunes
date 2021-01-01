//
//  ToolbarView.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 01.01.21.
//

import SwiftUI

struct ToolbarView: View {
    @State var player: Player

    var body: some View {
        HStack {
            PlayingTrackView(player: player)
                .frame(minWidth: 200, maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 90)
                .layoutPriority(2)
            
            PlayerControlsView(player: player)
                .padding(.top, 8)
                .padding(.trailing)
        }
    }
}
