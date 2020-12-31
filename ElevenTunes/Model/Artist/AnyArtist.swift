//
//  AnyArtist.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 31.12.20.
//

import Foundation
import SwiftUI

class TransientArtist: TransientPlaylist {
    override var type: PlaylistType { .artist }
    
    override var icon: Image { Image(systemName: "person") }
}
