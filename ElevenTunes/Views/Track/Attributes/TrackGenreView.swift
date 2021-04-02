//
//  TrackGenreView.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 02.04.21.
//

import SwiftUI

struct TrackGenreView: View {
	let track: Track
	@State var genre: String?

	var body: some View {
		Text(genre ?? "")
			.foregroundColor(.secondary)
			.whileActive(track.backend.demand([.genre]))
			.onReceive(track.backend.attribute(TrackAttribute.genre)) {
				setIfDifferent(self, \.genre, $0.value)
			}
	}
}

//struct TrackGenreView_Previews: PreviewProvider {
//    static var previews: some View {
//        TrackGenreView()
//    }
//}
