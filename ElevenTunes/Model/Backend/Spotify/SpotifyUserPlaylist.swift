//
//  SpotifyUserPlaylist+CoreDataClass.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 25.12.20.
//
//

import Foundation
import Combine
import SwiftUI

public class SpotifyUserPlaylist: SpotifyPlaylistBackend {
    public override var id: String { "spotify::userplaylist" }
}
