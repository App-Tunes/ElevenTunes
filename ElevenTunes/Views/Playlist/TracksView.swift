//
//  TracksView.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 18.12.20.
//

import SwiftUI

struct TracksView: View {
    @ObservedObject var playlist: Playlist
    
    @State var selected: Track?

    @Environment(\.player) private var player: Player
    @Environment(\.trackInterpreter) private var trackInterpreter: TrackInterpreter
    
    var body: some View {
        List(selection: $selected) {
            ForEach(playlist.tracks) { track in
                HStack {
                    Image(systemName: "music.note")
                    
                    Text(track[.ttitle])
                        .tag(track)
                        .onTapGesture(count: 2) {
                            player.play(track)
                        }
                }
            }
        }
            .frame(minWidth: 200, maxWidth: .infinity, minHeight: 50, maxHeight: .infinity)
            .onDrop(of: TrackInterpreter.types, delegate: TrackDropInterpreter(trackInterpreter, playlist: playlist))
    }
}

struct TracksView_Previews: PreviewProvider {
    static var previews: some View {
        TracksView(playlist: LibraryMock.playlist())
    }
}
