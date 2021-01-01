//
//  AnyAlbum.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 31.12.20.
//

import Foundation
import SwiftUI

class TransientAlbum: TransientPlaylist {
    override var type: PlaylistType { .album }
    
    override var icon: Image { Image(systemName: "opticaldisc") }
}
