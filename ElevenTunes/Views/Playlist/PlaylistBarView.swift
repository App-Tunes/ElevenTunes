//
//  PlaylistBarView.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 15.12.20.
//

import SwiftUI

struct PlaylistBarView: View {
    @ObservedObject var playlist: Playlist

    var body: some View {
        GeometryReader { geo in
            Text("\(playlist.tracks.count) tracks")
                .position(x: geo.size.width / 2, y: geo.size.height / 2 - 5)
        }
            .frame(minWidth: 200)
            .frame(height: 20)
    }
}

//struct PlaylistBarView_Previews: PreviewProvider {
//    static var previews: some View {
//        PlaylistBarView(playlist: LibraryMock.playlist())
//    }
//}
