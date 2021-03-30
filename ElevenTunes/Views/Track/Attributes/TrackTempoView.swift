//
//  TrackTempoView.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 07.03.21.
//

import SwiftUI

struct TrackTempoView: View {
	let track: Track
	@State var tempo: Tempo?

    var body: some View {
		Text(tempo?.title ?? "")
			.foregroundColor(tempo?.color ?? .clear)
			.whileActive(track.backend.demand([.tempo]))
			.onReceive(track.backend.attribute(TrackAttribute.tempo)) {
				setIfDifferent(self, \.tempo, $0.value)
			}
    }
}

//struct TrackTempoView_Previews: PreviewProvider {
//    static var previews: some View {
//        TrackTempoView()
//    }
//}
