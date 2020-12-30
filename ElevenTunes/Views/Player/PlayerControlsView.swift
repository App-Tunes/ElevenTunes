//
//  PlayerControlsView.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 19.12.20.
//

import SwiftUI
import Combine

struct PlayingTrackView: View {
    @State var current: AnyTrack?
    @State var attributes: TypedDict<TrackAttribute> = .init()
    
    var body: some View {
        HStack {
            if let current = current {
                current.icon
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 15, height: 15)

                Text(attributes[TrackAttribute.title] ?? "Untitled Track")
            }
            else {
                Text("Nothing Playing").opacity(0.5)
            }
        }
        .onReceive(current?.attributes() ?? Just(.init()).eraseToAnyPublisher()) { attributes = $0 }
    }
}

struct PlayerControlsView: View {
    @State var player: Player
    
    @State var previous: AnyTrack?
    @State var current: AnyTrack?
    @State var next: AnyTrack?

    @State var isPlaying: Bool = false
    
    var body: some View {
        VStack {
            PlayingTrackView(current: current)
            
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
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 20))
                }
                    .buttonStyle(BorderlessButtonStyle())
                    .keyboardShortcut(.space, modifiers: [])

                Button(action: {
                    player.forwards()
                }) {
                    ZStack {
                        Image(systemName: "forward.end.fill")
                            .blinking(opacity: (1, 0.65), animates: player.$isAlmostNext)
                    }
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
//
//struct PlayerControlsView_Previews: PreviewProvider {
//    static var previews: some View {
//        let player = Player()
//        
//        PlayerControlsView(player: player)
//    }
//}
