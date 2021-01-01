//
//  PlaylistsView.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 18.12.20.
//

import SwiftUI
import Combine

struct PlaylistSectionView: View {
    @ObservedObject var section: PlaylistsView.FolderPlaylist
    
    var body: some View {
        if section.children != nil {
            OutlineGroup(section.children ?? [], children: \.children) { playlist in
                PlaylistRowView(playlist: playlist.backend)
                    .padding(.leading, 8)
            }
        }
    }
}

struct PlaylistsView: View {
    @State var directory: AnyPlaylist
    @State var topLevelChildren: [FolderPlaylist] = []
        
    @Environment(\.library) private var library: Library!
    
    var body: some View {
        List {
            ForEach(topLevelChildren) { category in
                if category.backend.supportsChildren() {
                    Section(header: PlaylistRowView(playlist: category.backend)) {
                        PlaylistSectionView(section: category)
                    }
                }
                else {
                    PlaylistRowView(playlist: category.backend)
                }
            }
        }
        .frame(minWidth: 0, maxWidth: 800, maxHeight: .infinity)
        .onDrop(of: ContentInterpreter.types, delegate: PlaylistDropInterpreter(library.interpreter, parent: directory))
        .onReceive(directory.children()) { topLevelChildren = $0.map { FolderPlaylist($0, isTopLevel: true) } }
   }
}

extension PlaylistsView {
    class FolderPlaylist: ObservableObject, Identifiable {
        let backend: AnyPlaylist
        let isTopLevel: Bool
        var observation: AnyCancellable? = nil

        @Published var children: [FolderPlaylist]? = nil

        var id: String { backend.id }
        
        init(_ backend: AnyPlaylist, isTopLevel: Bool = false) {
            self.backend = backend
            self.isTopLevel = isTopLevel
            
            if backend.supportsChildren() {
                children = []
                observation = backend.children()
                    .map { $0.map { FolderPlaylist($0) } }
                    .assignWeak(to: \FolderPlaylist.children, on: self)
            }
        }
    }
}

//struct PlaylistsView_Previews: PreviewProvider {
//    static var previews: some View {
//        PlaylistsView(directory: Playlist(LibraryMock.directory()))
//    }
//}
