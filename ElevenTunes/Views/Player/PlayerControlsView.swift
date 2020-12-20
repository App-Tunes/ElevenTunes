//
//  PlayerControlsView.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 19.12.20.
//

import SwiftUI

struct PlayerControlsView: View {
    @State var player: Player
    
    @State var previous: Track?
    @State var current: Track?
    @State var next: Track?

    @State var isPlaying: Bool = false

    var body: some View {
        VStack {
            Text(current?[.ttitle] ?? "Nothing Playing")
            
            HStack {
                Button(action: {
                    player.backwards()
                }) {
                    Image(systemName: "backward.end.fill")
                }
                    .buttonStyle(BorderlessButtonStyle())
                    .disabled(previous == nil && current == nil)

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
                
                Button(action: {
                    player.forwards()
                }) {
                    Image(systemName: "forward.end.fill")
                }
                    .buttonStyle(BorderlessButtonStyle())
                    .disabled(next == nil && current == nil)
            }
        }
        .onReceive(player.$previous) { self.previous = $0 }
        .onReceive(player.$current) { self.current = $0 }
        .onReceive(player.$next) { self.next = $0 }
        .onReceive(player.$state) { self.isPlaying = $0.isPlaying }

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
