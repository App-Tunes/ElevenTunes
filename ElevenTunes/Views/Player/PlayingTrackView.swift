//
//  PlayingTrackView.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 01.01.21.
//

import Foundation

import SwiftUI
import Combine

struct PlayingTrackView: View {
    @State var player: Player

    @State var current: Track?
    @State var attributes: TypedDict<TrackAttribute> = .init()
    
    var body: some View {
        HStack {
            if let current = current {
                TrackCellView(track: current)
            }
            else {
                Text("Nothing Playing").opacity(0.5)
            }
        }
        .padding(.top, 8)
        .onReceive(player.$current) { self.current = Track($0) }
    }
}
