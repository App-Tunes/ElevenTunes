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
        HStack {
            Text("Playlist Bar!")
        }
            .frame(minWidth: 200)
            .frame(height: 25)
    }
}

struct PlaylistBarView_Previews: PreviewProvider {
    static var previews: some View {
        PlaylistBarView(playlist: LibraryMock.playlist())
    }
}
