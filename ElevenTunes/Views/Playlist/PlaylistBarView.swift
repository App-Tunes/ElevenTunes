//
//  PlaylistBarView.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 15.12.20.
//

import SwiftUI

struct PlaylistBarView: View {
    let playlist: Playlist
    @State var contentMask: PlaylistContentMask = []
    @State var tracks: [AnyTrack] = []
    @State var attributes: TypedDict<PlaylistAttribute> = .init()

    var body: some View {
        HStack {
            Spacer()
                .frame(width: 8)

            // TODO Make draggable
            playlist.backend.icon
                .foregroundColor(playlist.backend.accentColor)
            
            Text(attributes[PlaylistAttribute.title] ?? "...")
                .foregroundColor(.secondary)

            Spacer()

            Text("\(tracks.count) tracks")
                .foregroundColor(.secondary)
            
            Button {
                // TODO View playlist info
            } label: {
                Image(systemName: "gearshape")
            }
            .buttonStyle(BorderlessButtonStyle())
            .disabled(true)

            Spacer()
                .frame(width: 8)
        }
            .frame(minWidth: 200)
            .frame(height: 30)
            .visualEffectBackground(material: .headerView, blendingMode: .withinWindow)
            .onReceive(playlist.backend.tracks()) { tracks = $0 }
            .onReceive(playlist.backend.attributes()) { attributes = $0 }
    }
}

//struct PlaylistBarView_Previews: PreviewProvider {
//    static var previews: some View {
//        PlaylistBarView(playlist: LibraryMock.playlist())
//    }
//}
