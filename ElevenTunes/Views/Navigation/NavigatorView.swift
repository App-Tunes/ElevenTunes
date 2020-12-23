//
//  NavigatorView.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 15.12.20.
//

import SwiftUI

struct NavigatorView: View {
    @ObservedObject var directory: Playlist
    
    var body: some View {
        NavigationView {
            PlaylistsView(directory: directory)
        }
        .listStyle(SidebarListStyle())
    }
}

struct NavigatorView_Previews: PreviewProvider {
    static var previews: some View {
        NavigatorView(directory: LibraryMock.directory())
    }
}
