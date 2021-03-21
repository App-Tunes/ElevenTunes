//
//  PlayerAudioView.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 01.01.21.
//

import SwiftUI
import Combine

struct PlayerAudioView: View {
    let player: Player
    
	@State var volume: Double = 1
	@State var presents: Bool = false
		
	var volumeImage: Image {
		Image(systemName:
				volume == 0 ? "speaker.fill" :
				volume < 0.33 ? "speaker.wave.1.fill" :
				volume < 0.66 ? "speaker.wave.2.fill" :
				"speaker.wave.3.fill"
		)
	}
	
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
				volumeImage
					.frame(width: 25, alignment: .leading)
			}
				.popover(isPresented: $presents) {
					AudioSetupView()
				}
				.disabled(true)
        }
		.onReceive(player.singlePlayer.$volume) { self.volume = $0 }
    }
}
