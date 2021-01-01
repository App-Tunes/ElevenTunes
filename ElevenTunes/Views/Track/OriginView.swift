//
//  OriginView.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 01.01.21.
//

import SwiftUI
import Combine

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
