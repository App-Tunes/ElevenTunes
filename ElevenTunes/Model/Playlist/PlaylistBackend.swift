//
//  Backend.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 18.12.20.
//

import Foundation

protocol PlaylistBackend {
    var tracks: [Track] { get }
    var children: [Playlist] { get }

    func add(tracks: [Track]) -> Bool
}
