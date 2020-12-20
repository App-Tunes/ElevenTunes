//
//  Backend.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 18.12.20.
//

import Foundation

protocol PlaylistBackend {
    func add(tracks: [Track]) -> Bool
    func add(children: [Playlist]) -> Bool
}
