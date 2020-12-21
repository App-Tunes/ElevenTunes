//
//  Backend.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 18.12.20.
//

import Foundation
import SwiftUI
import Combine

protocol PlaylistBackend: AnyObject {
    var frontend: Playlist? { get set }
        
    var icon: Image? { get }
    
    func load() -> AnyPublisher<([Track], [Playlist]), Error>

    func add(tracks: [Track]) -> Bool
    func add(children: [Playlist]) -> Bool
}
