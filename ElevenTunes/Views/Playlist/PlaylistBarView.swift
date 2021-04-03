//
//  PlaylistBarView.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 15.12.20.
//

import SwiftUI

struct PlaylistBarView: View {
    let playlist: Playlist
    @State var tracks: [Track]? = nil
    @State var title: String?

    var body: some View {
        HStack {
            Spacer()
                .frame(width: 8)

            // TODO Make draggable
            playlist.backend.icon
                .foregroundColor(playlist.backend.accentColor)
            
            Text(title ?? "...")
                .foregroundColor(.secondary)

            Spacer()

			Text(tracks != nil ? "\(tracks!.count) tracks" : "")
                .foregroundColor(.secondary)
            
            Button {
                // TODO View playlist info
            } label: {
                Image(systemName: "gearshape")
            }
            .buttonStyle(BorderlessButtonStyle())
            .disabled(true)

            Spacer()
                .frame(width: 8)
        }
            .frame(minWidth: 200)
            .frame(height: 30)
            .visualEffectBackground(material: .headerView, blendingMode: .withinWindow)
			.whileActive(playlist.backend.demand([PlaylistAttribute.title]))
			.onReceive(playlist.backend.attribute(PlaylistAttribute.title)) { snapshot in
				title = snapshot.value
			}
			.onReceive(playlist.backend.attribute(PlaylistAttribute.tracks)) { snapshot in
				tracks = (snapshot.value ?? []).map(Track.init)
			}
    }
}

struct PlaylistBarView_Previews: PreviewProvider {
    static var previews: some View {
        PlaylistBarView(playlist: Playlist(LibraryMock.playlist()))
    }
}
