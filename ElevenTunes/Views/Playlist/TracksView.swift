//
//  TracksView.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 18.12.20.
//

import SwiftUI

struct PlayTrackView: View {
    @State var playlist: Playlist
    @State var track: Track

    @Environment(\.player) private var player: Player
    @State var current: Track?
    @State var next: Track?

    var body: some View {
        Button(action: {
            player.play(PlayHistory(playlist, at: track))
        }) {
            ZStack {
                if [current, next].contains(track) {
                    Image(systemName: "play.fill")
                        .opacity(current == track ? 1 : 0.35)
                }
                
                Image(systemName: "play")
            }
        }
        .buttonStyle(BorderlessButtonStyle())
        .disabled(track._loadLevel == .none)
        .onReceive(player.$current) { self.current = $0 }
        .onReceive(player.$next) { self.next = $0 }
    }
}

struct TrackView: View {
    @ObservedObject var playlist: Playlist
    @ObservedObject var track: Track
    
    var body: some View {
        HStack {
            PlayTrackView(playlist: playlist, track: track)

            if track._loadLevel == .none {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(0.5, anchor: .center)
                
                Text("...")
            }
            else {
                track.icon.resizable().aspectRatio(contentMode: .fit).frame(width: 15, height: 15)
                
                Text(track[TrackAttribute.title] ?? "Unknown Track")
            }
        }
        .tag(track)
        .onAppear() { track.load(atLeast: .minimal) }
    }
}

struct TracksView: View {
    @ObservedObject var playlist: Playlist
    
    @State var selected: Track?

    @Environment(\.interpreter) private var interpreter: ContentInterpreter!
    
    var body: some View {
        List(selection: $selected) {
            ForEach(playlist._tracks.map { Track($0) } ) { track in
                TrackView(playlist: playlist, track: track)
                    .frame(height: 15)
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
