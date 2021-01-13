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
            ZStack(alignment: .center) {
                Rectangle()
                    .fill(Color.black)
                    .opacity(0.2)
				
				TrackImageView(track: track)
                
                PlayTrackView(track: track, context: context)
                    .font(.system(size: 14))
            }
            .frame(width: 28, height: 28)
            .cornerRadius(5)

            TrackCellView(track: track)
        }
    }
}
