//
//  PlaylistBarView.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 15.12.20.
//

import SwiftUI

struct PlaylistBarView: View {
    @State var playlist: AnyPlaylist
    @State var tracks: [AnyTrack] = []

    var body: some View {
        GeometryReader { geo in
            Text("\(tracks.count) tracks")
                .position(x: geo.size.width / 2, y: geo.size.height / 2 - 5)
        }
            .frame(minWidth: 200)
            .frame(height: 20)
            .onReceive(playlist.tracks()) { tracks = $0 }
    }
}

//struct PlaylistBarView_Previews: PreviewProvider {
//    static var previews: some View {
//        PlaylistBarView(playlist: LibraryMock.playlist())
//    }
//}
