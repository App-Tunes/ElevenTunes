//
//  MilkCoverView.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 01.01.21.
//

import SwiftUI
import Combine
import TunesUI

struct PlayerMilkyCoverView: View {
    @Environment(\.player) private var player: Player!

	@State var track: AnyTrack?
	@State var image: NSImage?
	
	var liveImage: AnyPublisher<NSImage?, Never>? {
		track?.previewImage
			.map(\.value)
			.eraseToAnyPublisher()
	}

    var body: some View {
		TransitioningImageView(image)
			.onReceive(player.$current) { newTrack in
				guard track?.id != newTrack?.id else { return }
				track = newTrack
			}
			.onReceive(liveImage, default: nil) { (img: NSImage?) in
				// TODO Add a timeout before which it's not set, but after which it's set to nil
				setIfDifferent(self, \.image, img)
			}
    }
}

//struct MilkyCoverView_Previews: PreviewProvider {
//    static var previews: some View {
//        MilkyCoverView()
//    }
//}
