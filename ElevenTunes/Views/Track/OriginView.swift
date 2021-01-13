//
//  OriginView.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 01.01.21.
//

import SwiftUI
import Combine

struct ArtistCellView: View {
    let artist: Playlist

	@State var title: PlaylistAttributes.ValueSnapshot<String?> = .missing()

    var body: some View {
        HStack {
			if title.state.isVersioned {
                if let url = artist.backend.origin {
                    UnderlinedLink(
                        description: title.value ?? "Unknown Artist",
                        destination: url
                    )
                }
                else {
                    Text(title.value ?? "Unknown Artist")
                }
            }
            else {
				Text(title.value ?? "...")
                    .opacity(0.5)
            }
        }
		.whileActive(artist.backend.demand([.title]))
		.onReceive(artist.backend.attribute(PlaylistAttribute.title)) { title = $0 }
    }
}

struct AlbumCellView: View {
    let album: Playlist
    
	@State var title: PlaylistAttributes.ValueSnapshot<String?> = .missing()
    
    var body: some View {
		HStack {
            album.backend.icon
            
			if title.state.isVersioned {
                if let url = album.backend.origin {
                    UnderlinedLink(
						description: title.value ?? "Unknown Album",
                        destination: url
                    )
                }
                else {
                    Text(title.value ?? "Unknown Album")
                }
            }
            else {
                Text(title.value ?? "...")
                    .opacity(0.5)
            }
        }
		.whileActive(album.backend.demand([.title]))
		.onReceive(album.backend.attribute(PlaylistAttribute.title)) { title = $0 }
    }
}

struct TrackOriginView: View {
    let artists: [Playlist]
    let album: Playlist?
    
    var body: some View {
        HStack {
            Image(systemName: "person.2")
            
            if artists.isEmpty {
                Text("Unknown Artist")
                    .opacity(0.5)
            }
            else {
                ForEach(artists, id: \.id) {
                    ArtistCellView(artist: $0)
                }
            }
            
            if let album = album {
                AlbumCellView(album: album)
            }
        }
    }
}
