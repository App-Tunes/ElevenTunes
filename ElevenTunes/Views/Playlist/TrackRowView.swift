//
//  TrackRowView.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 28.12.20.
//

import Foundation
import SwiftUI

struct TrackRowView: View {
    let track: Track
    
    @State var context: PlayHistoryContext

    var body: some View {
        HStack {
            PlayTrackImageView(track: track, context: context)
				.frame(width: 28, height: 28)

            TrackCellView(track: track)
			
			Spacer()
			
			TrackTempoView(track: track)

			TrackKeyView(track: track)
				.padding(.leading)
        }
    }
}
