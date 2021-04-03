//
//  TrackYearView.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 02.04.21.
//

import SwiftUI

struct TrackYearView: View {
	let track: Track
	@State var year: Int?

	var body: some View {
		Text(year.map { String($0) } ?? "")
			.foregroundColor(.secondary)
			.whileActive(track.backend.demand([.year]))
			.onReceive(track.backend.attribute(TrackAttribute.year)) {
				setIfDifferent(self, \.year, $0.value)
			}
	}
}

struct TrackYearView_Previews: PreviewProvider {
    static var previews: some View {
		TrackYearView(track: Track(LibraryMock.track()))
			.frame(width: 200, height: 100)
    }
}
