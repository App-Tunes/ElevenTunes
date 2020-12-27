//
//  PlaylistView.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 15.12.20.
//

import SwiftUI

struct PlaylistView: View {
    @ObservedObject var playlist: Playlist
    
    @Environment(\.library) var library: Library!

    var body: some View {
        HSplitView {
            VStack {
//                FilterBarView()
                
//                Divider()
                
                if playlist._loadLevel < .minimal {
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
        .onAppear() { playlist.load(atLeast: .detailed, library: library) }
    }
}

struct PlaylistView_Previews: PreviewProvider {
    static var previews: some View {
        PlaylistView(playlist: Playlist(LibraryMock.playlist()))
    }
}
