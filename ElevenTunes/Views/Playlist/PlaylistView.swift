//
//  PlaylistView.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 15.12.20.
//

import SwiftUI

struct PlaylistView: View {
    @ObservedObject var playlist: Playlist

    var body: some View {
        HSplitView {
            VStack {
//                FilterBarView()
                
//                Divider()
                
                if !playlist.isLoaded {
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
        .onAppear() {
            playlist.load()
        }
    }
}

struct PlaylistView_Previews: PreviewProvider {
    static var previews: some View {
        PlaylistView(playlist: LibraryMock.playlist())
    }
}
