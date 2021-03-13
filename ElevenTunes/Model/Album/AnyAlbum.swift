//
//  AnyAlbum.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 31.12.20.
//

import Foundation
import SwiftUI

protocol AnyAlbum: AnyPlaylist {
}

class TransientAlbum: TransientPlaylist, AnyAlbum {
	init(attributes: TypedDict<PlaylistAttribute>) {
		super.init(.hybrid, attributes: attributes)
	}
}
