//
//  PlayerAudioView.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 01.01.21.
//

import SwiftUI
import Combine
import TunesUI

struct PlayerAudioView: View {
    let player: Player
    
	@State var volume: Double = 1
	@State var presents: Bool = false
		
    var body: some View {
        HStack {
			Slider(value: Binding(
				get: { player.singlePlayer.volume },
				set: { player.singlePlayer.volume = $0 }
			), in: 0...1)
                .frame(width: 80)
            
			Button(action: {
				presents.toggle()
			}) {
				AudioUI.imageForVolume(volume)
					.frame(width: 25, alignment: .leading)
			}
				.popover(isPresented: $presents) {
					AudioSetupView(context: player.context)
				}
        }
		.onReceive(player.singlePlayer.$volume) { self.volume = $0 }
    }
}
