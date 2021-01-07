//
//  NavigatorView.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 15.12.20.
//

import SwiftUI
import Combine

struct NavigatorView: View {
    @State var directory: Playlist
        
    @Binding var selection: Set<Playlist>

    @Environment(\.library) private var library: Library!

    var body: some View {
        VStack(spacing: 0) {
            List(selection: $selection) {
                NavigationSearchBar()

                PlaylistsView(directory: directory)
            }
                .contentShape(Rectangle())
            .onDrop(of: ContentInterpreter.types, delegate: PlaylistDropInterpreter(library.interpreter, parent: directory.backend, context: .playlists))

            NavigationBarView()
        }
    }
}

//struct NavigatorView_Previews: PreviewProvider {
//    static var previews: some View {
//        NavigatorView(directory: Playlist(LibraryMock.directory()))
//    }
//}
