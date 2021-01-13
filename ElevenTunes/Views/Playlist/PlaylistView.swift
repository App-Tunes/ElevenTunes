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
    
	@State var state: PlaylistAttributes.State = .missing
    
    var body: some View {
        HSplitView {
            ZStack(alignment: .bottom) {
				if !state.isKnown {
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
		.whileActive(playlist.backend.demand([.tracks]))
		.onReceive(playlist.backend.attribute(PlaylistAttribute.tracks)) {
			state ?= $0.state
		}
    }
}

//struct PlaylistView_Previews: PreviewProvider {
//    static var previews: some View {
//        PlaylistView(playlist: Playlist(LibraryMock.playlist()))
//    }
//}
