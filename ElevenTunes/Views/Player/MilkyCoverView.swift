//
//  MilkCoverView.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 01.01.21.
//

import SwiftUI
import Combine

struct PlayerMilkyCoverView: View {
    @Environment(\.player) private var player: Player!

    @State var track: AnyTrack?
    
    var body: some View {
        MilkyCoverView(track: track)
            .onReceive(player.$current) { track = $0 }
    }
}

struct MilkyCoverView: View {
    var track: AnyTrack?
    
	@State var image: NSImage? = nil

	var liveImage: AnyPublisher<NSImage?, Never>? {
		track?.attributes
			.filtered(toJust: TrackAttribute.previewImage)
			.map(\.value)
			.eraseToAnyPublisher()
	}
	
    var body: some View {
        MilkyImageView(image: image)
			.onReceive(liveImage, default: nil) { (img: NSImage?) in
				image = img
			}
    }
}

struct MilkyCoverView_Previews: PreviewProvider {
    static var previews: some View {
        MilkyCoverView()
    }
}
