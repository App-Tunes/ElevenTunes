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
        if let playlist = playlists.one {
            PlaylistView(playlist: playlist)
        }
        // TODO Currently freezes the view in an infinite loop
        // need caches.
//        else if playlists.count < 5 {
//            PlaylistView(playlist: Playlist(MultiPlaylist(playlists.map { $0.backend })))
//        }
    }
}

//struct PlaylistMultiplicityView_Previews: PreviewProvider {
//    static var previews: some View {
//        PlaylistMultiplicityView()
//    }
//}
