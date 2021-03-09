//
//  PlayerControlsView.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 19.12.20.
//

import SwiftUI
import Combine

struct PlayerControlsView: View {
    @State var player: Player
    
    @State var previous: AnyTrack?
    @State var current: AnyTrack?
    @State var next: AnyTrack?

	@State var repeatEnabled: Bool = false
	@State var isPlaying: Bool = false

    var playStateControls: some View {
        HStack {
            Button(action: {
                player.backwards()
            }) {
                Image(systemName: "backward.fill")
                    .font(.system(size: 16))
            }
                .disabled(previous == nil && current == nil)

            Button(action: {
                player.toggle()
            }) {
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 24))
            }
				.frame(width: 25)
                .keyboardShortcut(.space, modifiers: [])

            Button(action: {
                player.forwards()
            }) {
                ZStack {
                    Image(systemName: "forward.fill")
                        .blinking(opacity: (1, 0.65), animates: player.$isAlmostNext)
                        .font(.system(size: 16))
                }
            }
                .disabled(next == nil && current == nil)
        }
    }
    
    var body: some View {
        HStack {
            playStateControls
                .padding(.trailing, 5)

            Button(action: {
                
            }) {
                Image(systemName: "shuffle")
                    .font(.system(size: 14))
            }
                .disabled(true)
            
            Button(action: {
				player.repeatEnabled.toggle()
            }) {
                Image(systemName: "repeat")
                    .font(.system(size: 14))
            }
				.foregroundColor(repeatEnabled ? .accentColor : .secondary)
            
            PlayerAudioView(player: player)
                .padding(.leading)
        }
        .buttonStyle(BorderlessButtonStyle())
        .onReceive(player.$previous) { self.previous = $0 }
        .onReceive(player.$current) { self.current = $0 }
        .onReceive(player.$next) { self.next = $0 }
		.onReceive(player.$state) { self.isPlaying = $0.isPlaying }
		.onReceive(player.$repeatEnabled) { self.repeatEnabled = $0 }
    }
}
//
//struct PlayerControlsView_Previews: PreviewProvider {
//    static var previews: some View {
//        let player = Player()
//        
//        PlayerControlsView(player: player)
//    }
//}
