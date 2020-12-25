//
//  Transient.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 18.12.20.
//

import Foundation
import AVFoundation
import Combine

class LibraryMock {
    static func directory(_ title: String = "Mock Directory") -> Playlist {
        let children = [
            playlist("\(title) -> 1"),
            playlist("\(title) -> 2")
        ]
                
        return Playlist(attributes: .init([
            .title: title
        ]), tracks: children.flatMap { $0.tracks }, children: children)
    }
    
    static func playlist(_ title: String = "Mock Playlist") -> Playlist {
        let tracks = [
            "\(title) -> 1", "\(title) -> 2", "\(title) -> 3"
        ].map(track)
        
        return Playlist(attributes: .init([
            .title: title
        ]), tracks: tracks)
    }
    
    static func track(_ title: String) -> Track {
        Track(nil, attributes: .init([
            .title: title
        ]))
    }
}
