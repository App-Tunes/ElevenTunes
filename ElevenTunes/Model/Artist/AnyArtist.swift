//
//  AnyArtist.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 31.12.20.
//

import Foundation
import SwiftUI

protocol AnyArtist: AnyPlaylist {
}

class TransientArtist: TransientPlaylist, AnyArtist {
	static let splitRegex = try! NSRegularExpression(pattern: "((\\s*[,;])|(\\s+((f(ea)?t(uring)?\\.?)|[&x]))|(\\s+vs))\\s+", options: [])

	init(attributes: TypedDict<PlaylistAttribute>) {
		super.init(.hybrid, attributes: attributes)
	}
	
	static func splitNames(_ string: String) -> [String] {
		splitRegex.split(string: string)
	}
}
