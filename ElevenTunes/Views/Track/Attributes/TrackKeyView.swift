//
//  TrackKeyView.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 07.03.21.
//

import SwiftUI

struct TrackKeyView: View {
	let track: Track
	@State var key: MusicalKey?

    var body: some View {
		Text(key?.title ?? "")
			.foregroundColor(key?.color ?? .clear)
			.whileActive(track.backend.demand([.key]))
			.onReceive(track.backend.attribute(TrackAttribute.key)) {
				setIfDifferent(self, \.key, $0.value)
			}
    }
}

//struct TrackKeyView_Previews: PreviewProvider {
//    static var previews: some View {
//        TrackKeyView()
//    }
//}
