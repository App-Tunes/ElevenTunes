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
    
    @State var contentMask: PlaylistContentMask = []

    var body: some View {
        HSplitView {
            VStack {
//                FilterBarView()
                
//                Divider()
                
                if !contentMask.isSuperset(of: [.minimal, .tracks]) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                }
                else {
                    TracksView(playlist: playlist)
                    
                    Divider()
                    
                    PlaylistBarView(playlist: playlist)
                        .layoutPriority(2)
                }
            }
                .layoutPriority(2)
                        
//            TrackInfoView()
        }
        .listStyle(DefaultListStyle())
        .onReceive(playlist.backend.cacheMask()) { contentMask = $0 }
        .onReceive(playlist.backend.tracks()) { _ in }  // Request tracks to load
    }
}

//struct PlaylistView_Previews: PreviewProvider {
//    static var previews: some View {
//        PlaylistView(playlist: Playlist(LibraryMock.playlist()))
//    }
//}
