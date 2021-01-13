//
//  TrackImageView.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 13.01.21.
//

import SwiftUI

struct TrackImageView: View {
	let track: Track?
	@State var image: TrackAttributes.ValueSnapshot<NSImage?> = .missing()

    var body: some View {
		Group {
			if let track = track {
				if case .error = image.state {
					Image(systemName: "exclamationmark.triangle")
				}
				else if !image.state.isVersioned {
					ProgressView()
						.progressViewStyle(CircularProgressViewStyle())
						.scaleEffect(0.5, anchor: .center)
				}
				else if let image = image.value {
					Image(nsImage: image)
						.resizable().scaledToFit()
				}
				else {
					track.backend.icon
				}
			}
			else {
				Image(systemName: "music.note")
			}
		}
		.onReceive(track?.backend.previewImage, default: .missing()) {
			image = $0
		}
    }
}

//struct TrackImageView_Previews: PreviewProvider {
//    static var previews: some View {
//        TrackImageView()
//    }
//}
