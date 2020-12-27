//
//  DBPlaylist+Properties.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 27.12.20.
//

import Foundation

extension DBPlaylist {
    func merge(attributes: TypedDict<PlaylistAttribute>) {
        if let title = attributes[PlaylistAttribute.title] { self.title = title }
        _attributes = cachedAttributes
    }
    
    var cachedAttributes: TypedDict<PlaylistAttribute> {
        let dict = TypedDict<PlaylistAttribute>()
        dict[PlaylistAttribute.title] = title
        return dict
    }
}
