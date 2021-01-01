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

    @State var isPlaying: Bool = false
    
    var body: some View {
        HStack {
            Button(action: {
                
            }) {
                Image(systemName: "shuffle")
                    .font(.system(size: 14))
            }
                .buttonStyle(BorderlessButtonStyle())
                .disabled(true)
                .padding(.trailing, 3)

            Button(action: {
                player.backwards()
            }) {
                Image(systemName: "backward.fill")
                    .font(.system(size: 16))
            }
                .buttonStyle(BorderlessButtonStyle())
                .disabled(previous == nil && current == nil)

            Button(action: {
                player.toggle()
            }) {
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 24))
            }
                .buttonStyle(BorderlessButtonStyle())
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
                .buttonStyle(BorderlessButtonStyle())
                .disabled(next == nil && current == nil)
            
            Button(action: {
                
            }) {
                Image(systemName: "repeat")
                    .font(.system(size: 14))
            }
                .buttonStyle(BorderlessButtonStyle())
                .disabled(true)
                .padding(.leading, 3)
        }
        .onReceive(player.$previous) { self.previous = $0 }
        .onReceive(player.$current) { self.current = $0 }
        .onReceive(player.$next) { self.next = $0 }
        .onReceive(player.$state) { self.isPlaying = $0.isPlaying }

        .frame(minWidth: 500)
        .frame(height: 50)
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
