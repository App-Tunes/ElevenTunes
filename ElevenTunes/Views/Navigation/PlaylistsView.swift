//
//  PlaylistsView.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 18.12.20.
//

import SwiftUI
import Combine

class FolderPlaylist: ObservableObject, Identifiable {
    let backend: AnyPlaylist
    var observation: AnyCancellable? = nil

    @Published var children: [FolderPlaylist]? = nil

    var id: String { backend.id }
    
    init(_ backend: AnyPlaylist) {
        self.backend = backend
        
        if backend.supportsChildren() {
            children = []
            observation = backend.children()
                .map { $0.map(FolderPlaylist.init) }
                .assignWeak(to: \FolderPlaylist.children, on: self)
        }
    }
}

struct PlaylistsView: View {
    @State var directory: AnyPlaylist
    @State var topLevelChildren: [FolderPlaylist] = []
        
    @Environment(\.library) private var library: Library!
    
    var body: some View {
        List(topLevelChildren, children: \.children) { playlist in
            PlaylistRowView(playlist: playlist.backend)
                .padding(.leading, 8)
        }
        .frame(minWidth: 0, maxWidth: 800, maxHeight: .infinity)
        .onDrop(of: ContentInterpreter.types, delegate: PlaylistDropInterpreter(library.interpreter, parent: directory))
        .onReceive(directory.children()) { topLevelChildren = $0.map(FolderPlaylist.init) }
   }
}

//struct PlaylistsView_Previews: PreviewProvider {
//    static var previews: some View {
//        PlaylistsView(directory: Playlist(LibraryMock.directory()))
//    }
//}
