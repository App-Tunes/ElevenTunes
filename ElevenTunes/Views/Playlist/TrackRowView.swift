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
            PlayTrackView(track: track, context: context)
                .font(.system(size: 14))

            TrackCellView(track: track)
        }
    }
}
