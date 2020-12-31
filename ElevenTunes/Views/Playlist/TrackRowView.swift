//
//  TrackRowView.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 28.12.20.
//

import Foundation
import SwiftUI

struct PlayTrackView: View {
    @State var track: AnyTrack
    @State var context: PlayHistoryContext

    @Environment(\.player) private var player: Player!
    @State var current: AnyTrack?
    @State var next: AnyTrack?

    var body: some View {
        Button(action: {
            player.play(PlayHistory(context: context))
        }) {
            ZStack {
                if track.id == next?.id {
                    Image(systemName: "play.fill")
                        .blinking(
                            // If track is next AND current, start with 1 and blink downwards.
                            // otherwise, start half translucent and blink upwards
                            opacity: track.id == current?.id ? (1, 0.5) : (0.35, 1),
                            animates: player.$isAlmostNext
                        )
                }
                else if track.id == current?.id {
                    Image(systemName: "play.fill")
                }
                
                Image(systemName: "play")
            }
        }
        .buttonStyle(BorderlessButtonStyle())
        .onReceive(player.$current) { self.current = $0 }
        .onReceive(player.$next) { self.next = $0 }
    }
}

struct ArtistCellView: View {
    let artist: AnyPlaylist

    @State var contentMask: PlaylistContentMask = []
    @State var attributes: TypedDict<PlaylistAttribute> = .init()

    var body: some View {
        HStack {
            if contentMask.contains(.minimal) {
                if let url = artist.origin {
                    UnderlinedLink(
                        description: attributes[PlaylistAttribute.title] ?? "Unknown Artist",
                        destination: url
                    )
                }
                else {
                    Text(attributes[PlaylistAttribute.title] ?? "Unknown Artist")
                }
            }
            else {
                Text(attributes[PlaylistAttribute.title] ?? "...")
                    .opacity(0.5)
            }
        }
        .onReceive(artist.attributes()) { attributes = $0 }
        .onReceive(artist.cacheMask()) { contentMask = $0 }
    }
}

struct AlbumCellView: View {
    let album: AnyPlaylist
    
    @State var contentMask: PlaylistContentMask = []
    @State var attributes: TypedDict<PlaylistAttribute> = .init()
    
    var body: some View {
        HStack {
            album.icon
            
            if contentMask.contains(.minimal) {
                if let url = album.origin {
                    UnderlinedLink(
                        description: attributes[PlaylistAttribute.title] ?? "Unknown Album",
                        destination: url
                    )
                }
                else {
                    Text(attributes[PlaylistAttribute.title] ?? "Unknown Album")
                }
            }
            else {
                Text(attributes[PlaylistAttribute.title] ?? "...")
                    .opacity(0.5)
            }
        }
        .onReceive(album.attributes()) { attributes = $0 }
        .onReceive(album.cacheMask()) { contentMask = $0 }
    }
}

struct TrackOriginView: View {
    let artists: [AnyPlaylist]
    let album: AnyPlaylist?
    
    @State var albumAttributes: TypedDict<TrackAttribute> = .init()

    var body: some View {
        HStack {
            Image(systemName: "person.2")
            
            if artists.isEmpty {
                Text("Unknown Artist")
                    .opacity(0.5)
            }
            else {
                ForEach(artists, id: \.id) {
                    ArtistCellView(artist: $0)
                }
            }
            
            if let album = album {
                AlbumCellView(album: album)
            }
        }
    }
}

struct TrackRowView: View {
    @State var track: AnyTrack
    @State var context: PlayHistoryContext

    @State var contentMask: TrackContentMask = []
    @State var artists: [AnyPlaylist] = []
    @State var album: AnyPlaylist? = nil
    @State var attributes: TypedDict<TrackAttribute> = .init()

    @Environment(\.library) var library: Library!
    
    var body: some View {
        HStack {
            PlayTrackView(track: track, context: context)
                .font(.system(size: 14))

            if !contentMask.contains(.minimal) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(0.5, anchor: .center)
                
                Text(attributes[TrackAttribute.title] ?? "...")
                    .opacity(0.5)
            }
            else {
                track.icon
                    .resizable()
                    .foregroundColor(track.accentColor)
                    .saturation(0.5)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 20, height: 20)

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
        .onReceive(track.artists()) { artists = $0 }
        .onReceive(track.album()) { album = $0 }
        .onReceive(track.attributes()) { attributes = $0 }
        .onReceive(track.cacheMask()) { contentMask = $0 }
    }
}
