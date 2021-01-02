//
//  PlaylistBarView.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 15.12.20.
//

import SwiftUI

struct PlaylistBarView: View {
    let playlist: Playlist
    @State var tracks: [AnyTrack] = []

    var body: some View {
        GeometryReader { geo in
            Text("\(tracks.count) tracks")
                .position(x: geo.size.width / 2, y: geo.size.height / 2 - 5)
                .foregroundColor(.secondary)
        }
            .frame(minWidth: 200)
            .padding(.top, 6)
            .frame(height: 25)
            .visualEffectBackground(material: .headerView, blendingMode: .withinWindow)
            .onReceive(playlist.backend.tracks()) { tracks = $0 }
    }
}

//struct PlaylistBarView_Previews: PreviewProvider {
//    static var previews: some View {
//        PlaylistBarView(playlist: LibraryMock.playlist())
//    }
//}
