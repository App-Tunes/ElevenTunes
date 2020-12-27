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
    @Environment(\.interpreter) private var interpreter: ContentInterpreter!
    
    var body: some View {
        List(selection: $selected) {
            ForEach(playlist._tracks.map { Track($0) } ) { track in
                HStack {
                    Image(systemName: "music.note")
                    
                    Text(track[TrackAttribute.title] ?? "Unknown Track")
                        .tag(track)
                        .onTapGesture(count: 2) {
                            player.play(PlayHistory(playlist, at: track))
                        }
                }
                .frame(height: 15)
                .onAppear() { track.load(atLeast: .minimal) }
            }
        }
        .frame(minWidth: 200, maxWidth: .infinity, minHeight: 50, maxHeight: .infinity)
        .onDrop(of: ContentInterpreter.types, delegate: PlaylistDropInterpreter(interpreter, parent : playlist))
    }
}

struct TracksView_Previews: PreviewProvider {
    static var previews: some View {
        TracksView(playlist: Playlist(LibraryMock.playlist()))
    }
}
