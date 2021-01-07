//
//  NavigationBarView.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 02.01.21.
//

import SwiftUI

struct NavigationBarView: View {
    @Environment(\.library) private var library: Library!
    
    func createPlaylist(_ playlist: TransientPlaylist) {
        let success = library.mainPlaylist.import(library: DirectLibrary(allPlaylists: [playlist]))
        if !success {
            NSAlert.warning(title: "Creation failure", text: "Failed to create new playlist")
        }
    }
    
    var addFolderViews: some View {
        HStack {
            Button {
                let playlist = TransientPlaylist(.tracks, attributes: .init([
                    .title: "New Playlist"
                ]))
                createPlaylist(playlist)
            } label: {
                Image(systemName: "music.note.list")
                    .badge(systemName: "plus.circle.fill")
            }

            Button {
                let playlist = TransientPlaylist(.playlists, attributes: .init([
                    .title: "New Folder"
                ]))
                createPlaylist(playlist)
            } label: {
                Image(systemName: "folder")
                    .badge(systemName: "plus.circle.fill")
            }

            Button {
                let playlist = TransientPlaylist(.hybrid, attributes: .init([
                    .title: "New Hybrid Folder"
                ]))
                createPlaylist(playlist)
            } label: {
                Image(systemName: "questionmark.folder")
                    .badge(systemName: "plus.circle.fill")
            }
        }
    }
    
    var body: some View {
        HStack {
            Button {
                // TODO Change view
            } label: {
                Image(systemName: "sidebar.left")
            }
            .disabled(true)
            .padding(.leading, 8)
            
            Spacer()
                .frame(width: 20)
                    
            Button {
                // TODO Library View
            } label: {
                Image(systemName: "house")
            }
            .disabled(true)

            Spacer()
                .frame(width: 20)

            Button {
                // TODO Navigator: Back
            } label: {
                Image(systemName: "chevron.backward")
            }
            .disabled(true)

            Spacer()
                .frame(width: 15)

            Button {
                // TODO Navigator: Forward
            } label: {
                Image(systemName: "chevron.forward")
            }
            .disabled(true)

            Spacer()
            
            addFolderViews
                .padding(.trailing, 8)
        }
            .buttonStyle(BorderlessButtonStyle())
            .frame(maxWidth: .infinity)
            .frame(height: 30)
            .visualEffectBackground(material: .sidebar)
    }
}

struct NavigationBarView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationBarView()
    }
}
