//
//  Transient.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 18.12.20.
//

import Foundation
import AVFoundation
import Combine
import Cocoa

class LibraryMock {
    static func children(_ title: String = "Mock Directory") -> [TransientPlaylist] {
        [
            playlist("\(title) -> 1"),
            playlist("\(title) -> 2")
        ]
    }
    
    static func directory(_ title: String = "Mock Directory") -> TransientPlaylist {
        let children = self.children(title)
        return TransientPlaylist(.playlists, attributes: .init([
            .title: title
        ]), children: children)
    }
    
    static func playlist(_ title: String = "Mock Playlist") -> TransientPlaylist {
        let tracks = [
            "\(title) -> 1", "\(title) -> 2", "\(title) -> 3"
        ].map(track)
        
        return TransientPlaylist(.tracks, attributes: .init([
            .title: title
        ]), tracks: tracks)
    }
    
    static func track(_ title: String) -> MockTrack {
        MockTrack(attributes: .init([
            .title: title
        ]))
    }
}
