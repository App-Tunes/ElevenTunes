//
//  TrackDurationView.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 03.04.21.
//

import SwiftUI

struct TrackDurationView: View {
	let track: Track
	@State var duration: TimeInterval?

	var body: some View {
		HStack {
			Spacer()
			
			Text(duration?.humanReadableText ?? "")
				.foregroundColor(.secondary)
				.padding(.horizontal, 4)
		}
			.whileActive(track.backend.demand([.duration]))
			.onReceive(track.backend.attribute(TrackAttribute.duration)) {
				setIfDifferent(self, \.duration, $0.value)
			}
	}
}

struct TrackDurationView_Previews: PreviewProvider {
	static var previews: some View {
		TrackYearView(track: Track(LibraryMock.track()))
			.frame(width: 200, height: 100)
	}
}
