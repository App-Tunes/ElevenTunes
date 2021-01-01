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
            
            HStack {
                if let playlist = selection.one {
                    PlaylistView(playlist: playlist)
                }
                else {
                    Rectangle()
                        .opacity(0)
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
