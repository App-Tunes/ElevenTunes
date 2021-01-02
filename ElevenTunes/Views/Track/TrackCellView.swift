//
//  TrackCellView.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 01.01.21.
//

import SwiftUI
import Combine

struct TrackCellView: View {
    let track: Track

    @State var contentMask: TrackContentMask = []
    @State var artists: [AnyPlaylist] = []
    @State var album: AnyPlaylist? = nil
    @State var attributes: TypedDict<TrackAttribute> = .init()

    @Environment(\.library) var library: Library!

    var body: some View {
        HStack {
            if !contentMask.contains(.minimal) {
//                ProgressView()
//                    .progressViewStyle(CircularProgressViewStyle())
//                    .scaleEffect(0.5, anchor: .center)
//
                Text(attributes[TrackAttribute.title] ?? "...")
                    .opacity(0.5)
            }
            else {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .center, spacing: 4) {
                        track.backend.icon
                            .resizable()
                            .foregroundColor(track.backend.accentColor)
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 12, height: 12)

                        Text(attributes[TrackAttribute.title] ?? "Unknown Track")
                            .font(.system(size: 13))
                            .frame(alignment: .bottom)
                    }
                    
                    TrackOriginView(artists: artists, album: album)
                        .foregroundColor(.secondary)
                        .font(.system(size: 11))
                        .frame(alignment: .top)
                }
                .padding(.vertical, 4)
            }
            
            Spacer()
            
            let key = attributes[TrackAttribute.key]
            let tempo = attributes[TrackAttribute.bpm]
            
            Text(key?.title ?? "")
                .foregroundColor(key?.color ?? .clear)
                .frame(width: 30, alignment: .center)
                .padding(.leading)
            
            Text(tempo?.title ?? "")
                .foregroundColor(tempo?.color ?? .clear)
                .frame(width: 50, alignment: .trailing)
        }
        .lineLimit(1)
        .onReceive(track.backend.artists()) { artists = $0 }
        .onReceive(track.backend.album()) { album = $0 }
        .onReceive(track.backend.attributes()) { attributes = $0 }
        .onReceive(track.backend.cacheMask()) { contentMask = $0 }
    }
}
