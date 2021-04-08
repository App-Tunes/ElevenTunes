//
//  TrackAlbumView.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 08.04.21.
//

import SwiftUI

struct AlbumCellView: View {
	let album: Playlist
	
	@State var title: PlaylistAttributes.ValueSnapshot<String> = .missing()
	
	var body: some View {
		HStack {
			if title.state == .valid {
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
		.onReceive(album.backend.attribute(PlaylistAttribute.title)) {
			setIfDifferent(self, \.title, $0)
		}
		.id(album.id)
	}
}

struct TrackAlbumView: View {
	let track: Track
	let withIcon: Bool
	
	@State var album: Playlist?

	var body: some View {
		Group {
			if let album = album {
				if withIcon {
					Image(systemName: "opticaldisc")
				}
				
				AlbumCellView(album: album)
					.foregroundColor(.secondary)
			}
		}
			.whileActive(track.backend.demand([.album]))
			.onReceive(track.backend.attribute(TrackAttribute.album)) {
				setIfDifferent(self, \.album, $0.value.map { Playlist($0) })
			}
			.id(track.id)
	}
}

struct TrackAlbumView_Previews: PreviewProvider {
    static var previews: some View {
		TrackAlbumView(track: Track(LibraryMock.track()), withIcon: true)
    }
}
