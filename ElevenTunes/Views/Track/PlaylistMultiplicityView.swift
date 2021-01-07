//
//  PlaylistMultiplicityView.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 02.01.21.
//

import SwiftUI

struct PlaylistMultiplicityView: View {
    let playlists: [Playlist]
    
    var body: some View {
        let showPlaylists = playlists.filter { $0.backend.contentType != .playlists }
        
        if showPlaylists.isEmpty {
            Spacer()
            // TODO What do show? Certainly not tracks lol
        }
        else if let playlist = playlists.one {
            PlaylistView(playlist: playlist)
        }
        else {
            Spacer()
        }
        // TODO Currently freezes the view in an infinite loop
        // need caches.
//        else if showPlaylists.count < 5 {
//            PlaylistView(playlist: Playlist(MultiPlaylist(showPlaylists.map { $0.backend })))
//        }
    }
}

//struct PlaylistMultiplicityView_Previews: PreviewProvider {
//    static var previews: some View {
//        PlaylistMultiplicityView()
//    }
//}
