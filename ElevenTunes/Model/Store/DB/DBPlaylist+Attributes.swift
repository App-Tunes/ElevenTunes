//
//  DBPlaylist+Properties.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 27.12.20.
//

import Foundation

extension DBPlaylist {
    static let attributeProperties = Set([
        "title"
    ])

    func merge(attributes: TypedDict<PlaylistAttribute>) {
        guard !attributes.isEmpty else { return }
        
        if let title = attributes[PlaylistAttribute.title] { self.title = title }
        
        attributesP = cachedAttributes
    }
    
    var cachedAttributes: TypedDict<PlaylistAttribute> {
        let dict = TypedDict<PlaylistAttribute>()
        dict[PlaylistAttribute.title] = title
        return dict
    }
}
