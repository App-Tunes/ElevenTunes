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

	@State var title: PlaylistAttributes.ValueSnapshot<String> = .missing()

    var body: some View {
        HStack {
			if title.state == .valid {
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
		.help(title.value ?? "")
		.whileActive(artist.backend.demand([.title]))
		.onReceive(artist.backend.attribute(PlaylistAttribute.title)) {
			setIfDifferent(self, \.title, $0)
		}
		.id(artist.id)
    }
}

struct TrackArtistsView: View {
	let track: Track
	
	@State var snapshot: VolatileSnapshot<[Playlist], String> = .missing()

	var body: some View {
		HStack(spacing: 4) {
			if snapshot.state != .missing {
				if let artists = snapshot.value, !artists.isEmpty {
					ForEach(artists, id: \.id) {
						ArtistCellView(artist: $0)
						
						if $0 != artists.last {
							Text("·")
						}
					}
				}
				else {
					Text("Unknown Artist")
						.opacity(0.5)
				}
			}
			else {
				Text("...")
					.opacity(0.5)
			}
		}
			.foregroundColor(.secondary)
			.whileActive(track.backend.demand([.artists]))
			.onReceive(track.backend.attribute(TrackAttribute.artists)) {
				setIfDifferent(self, \.snapshot, $0.map { $0.map { Playlist($0) } })
			}
			.id(track.id)
	}
}

struct TrackArtistsView_Previews: PreviewProvider {
	static var previews: some View {
		TrackArtistsView(track: Track(LibraryMock.track()))
	}
}
