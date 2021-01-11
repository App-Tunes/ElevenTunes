//
//  PlaylistView.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 15.12.20.
//

import SwiftUI

struct PlaylistView: View {
    let playlist: Playlist
    @Environment(\.library) var library: Library!
    
    @State var tracks: [AnyTrack]? = nil
    
    var body: some View {
        HSplitView {
            ZStack(alignment: .bottom) {
                if tracks == nil {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                }
                else {
                    TracksView(playlist: playlist)
                    
                    PlaylistBarView(playlist: playlist)
                }
            }
                .layoutPriority(2)
                        
//            TrackInfoView()
        }
		.id(playlist.id)
        .listStyle(DefaultListStyle())
		.onReceive(playlist.backend.attributes.filtered(toJust: PlaylistAttribute.tracks)) { tracks = $0.value ?? [] }  // Request tracks to load
    }
}

//struct PlaylistView_Previews: PreviewProvider {
//    static var previews: some View {
//        PlaylistView(playlist: Playlist(LibraryMock.playlist()))
//    }
//}
