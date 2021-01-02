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
    @State var showType = true

    @Environment(\.library) var library: Library!

    var body: some View {
        HStack {
            if !contentMask.contains(.minimal) {
                if showType {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(0.5, anchor: .center)
                }
                
                Text(attributes[TrackAttribute.title] ?? "...")
                    .opacity(0.5)
            }
            else {
                if showType {
                    track.backend.icon
                        .resizable()
                        .foregroundColor(track.backend.accentColor)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 20, height: 20)
                }

                VStack(alignment: .leading) {
                    Text(attributes[TrackAttribute.title] ?? "Unknown Track")
                        .font(.system(size: 13))
                        .frame(alignment: .bottom)
                    
                    TrackOriginView(artists: artists, album: album)
                        .foregroundColor(.secondary)
                        .font(.system(size: 11))
                        .frame(alignment: .top)
                }
                .padding(.vertical, 4)
            }
        }
        .lineLimit(1)
        .onReceive(track.backend.artists()) { artists = $0 }
        .onReceive(track.backend.album()) { album = $0 }
        .onReceive(track.backend.attributes()) { attributes = $0 }
        .onReceive(track.backend.cacheMask()) { contentMask = $0 }
    }
}
