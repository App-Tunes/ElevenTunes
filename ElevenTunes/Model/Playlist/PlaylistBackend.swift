//
//  Backend.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 18.12.20.
//

import Foundation
import SwiftUI

protocol PlaylistBackend {
    var icon: Image? { get }
    
    func add(tracks: [Track]) -> Bool
    func add(children: [Playlist]) -> Bool
}
