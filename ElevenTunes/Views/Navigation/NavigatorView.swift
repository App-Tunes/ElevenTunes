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
    
    @State var selection = Set<Playlist>()
    
    var body: some View {
        HSplitView {
            List(selection: $selection) {
                NavigationSearchBar()
                    
                PlaylistsView(directory: directory)
            }
            // TODO hugging / compression resistance:
            // setting min height always compressed down to min height :<
            .frame(minWidth: 250, idealWidth: 250, maxWidth: 400)

            HStack {
                if let playlist = selection.one {
                    PlaylistView(playlist: playlist)
                }
            }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .layoutPriority(2)
        }
        .listStyle(SidebarListStyle())
    }
}

//struct NavigatorView_Previews: PreviewProvider {
//    static var previews: some View {
//        NavigatorView(directory: Playlist(LibraryMock.directory()))
//    }
//}
