//
//  M3UPlaylist.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 20.12.20.
//

import Foundation
import SwiftUI
import Combine

class M3UPlaylist: PlaylistBackend {
    var url: URL
    
    init(_ url: URL) {
        self.url = url
    }
    
    static func create(fromURL url: URL) throws -> Playlist {
        let playlistName = url.lastPathComponent
        
        return Playlist(M3UPlaylist(url), attributes: .init([
            .title: playlistName
        ]))
    }
    
    var icon: Image? { Image(systemName: "doc.text.fill") }

    func load() -> AnyPublisher<([Track], [Playlist]), Error> {
        let url = self.url
        
        return Future {
            let contents = try String(contentsOf: url)
            let folder = url.deletingLastPathComponent()
                    
            print(contents.split(whereSeparator: \.isNewline)
                    .compactMap { URL(fileURLWithPath: String($0), relativeTo: folder).absoluteURL })
            
            // TODO M3U Extensions
            let tracks = contents.split(whereSeparator: \.isNewline)
                .compactMap { URL(fileURLWithPath: String($0), relativeTo: folder).absoluteURL }
                .compactMap { try? FileTrack.create(fromURL: $0) }
            
            return (tracks, [])
        }.eraseToAnyPublisher()
    }
    
    func add(tracks: [Track]) -> Bool {
        // TODO
        return false
    }
    
    func add(children: [Playlist]) -> Bool {
        // TODO
        return false
    }
}
