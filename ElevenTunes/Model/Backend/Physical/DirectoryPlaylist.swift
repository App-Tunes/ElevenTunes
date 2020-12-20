//
//  DirectoryPlaylist.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 20.12.20.
//

import Foundation
import SwiftUI
import Combine

class DirectoryPlaylist: PlaylistBackend {
    var url: URL
    
    init(_ url: URL) {
        self.url = url
    }
    
    static func create(fromURL url: URL) throws -> Playlist {
        let manager = FileManager.default
        
        let children = try manager.contentsOfDirectory(at: url, includingPropertiesForKeys: [])
        let tracks = children.compactMap { url in
            try? FileTrack.create(fromURL: url)
        }
        // TODO Lazy children directories
        
        let playlistName = url.lastPathComponent
        
        return Playlist(DirectoryPlaylist(url), attributes: .init([
            AnyTypedKey.ptitle.id: playlistName
        ]), tracks: tracks)
    }
    
    var icon: Image? { Image(systemName: "folder.fill") }

    func add(tracks: [Track]) -> Bool {
        // TODO
        return false
    }
    
    func add(children: [Playlist]) -> Bool {
        // TODO
        return false
    }
}
