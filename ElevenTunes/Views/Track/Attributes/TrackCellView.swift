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

	@State var hasBasicInfo: Bool = false
    @State var artists: [Playlist] = []
    @State var album: Playlist? = nil
    
	@State var title: String?

    @Environment(\.library) var library: Library!

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .center, spacing: 4) {
                    track.backend.icon
                        .resizable()
                        .foregroundColor(track.backend.accentColor)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 12, height: 12)

                    if !hasBasicInfo {
                        Text(title ?? "...")
                            .font(.system(size: 13))
                            .frame(alignment: .bottom)
                    }
                    else {
                        Text(title ?? "Unknown Track")
                            .font(.system(size: 13))
                            .frame(alignment: .bottom)
                    }
                }
                
                TrackOriginView(artists: artists, album: album)
                    .foregroundColor(.secondary)
                    .font(.system(size: 11))
                    .frame(alignment: .top)
            }
            .padding(.vertical, 4)
			
			Spacer()
        }
        .lineLimit(1)
        .opacity(hasBasicInfo ? 1 : 0.5)
		.whileActive(track.backend.demand([.title, .album, .artists]))
		.onReceive(track.backend.attributes) { (snapshot, _) in
			setIfDifferent(self, \.hasBasicInfo, snapshot[TrackAttribute.title].state == .valid)
			setIfDifferent(self, \.title, snapshot[TrackAttribute.title].value)
			setIfDifferent(self, \.album, snapshot[TrackAttribute.album].value.map(Playlist.init))
			setIfDifferent(self, \.artists, snapshot[TrackAttribute.artists].value?.map(Playlist.init) ?? [])
		}
    }
}
