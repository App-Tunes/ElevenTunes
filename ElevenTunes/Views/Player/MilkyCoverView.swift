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

	@State var image: NSImage?
	@State var oldImage: NSImage?

	@State var transition: Double = 1
	
	var liveImage: AnyPublisher<NSImage?, Never>? {
		track?.previewImage
			.map(\.value)
			.eraseToAnyPublisher()
	}

    var body: some View {
		ZStack {
			Image(nsImage: oldImage ?? NSImage())
				.resizable()

			Image(nsImage: image ?? NSImage())
				.resizable()
				.opacity(transition)
		}
			.onReceive(player.$current) { newTrack in
				guard newTrack?.id != track?.id else {
					return
				}
				
				withAnimation(.instant) {
					oldImage = image
					track = newTrack
					transition = 0
				}
			}
			.onReceive(liveImage, default: nil) { (img: NSImage?) in
				withAnimation(.easeInOut(duration: 0.2)) {
					image = img
					transition = 1
				}
			}
    }
}

//struct MilkyCoverView_Previews: PreviewProvider {
//    static var previews: some View {
//        MilkyCoverView()
//    }
//}
