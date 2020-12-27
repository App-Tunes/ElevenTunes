//
//  DBTrack+Attributes.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 27.12.20.
//

import Foundation

extension DBTrack {
    static let attributeProperties = Set([
        "title"
    ])

    func merge(attributes: TypedDict<TrackAttribute>) {
        if let title = attributes[TrackAttribute.title] { self.title = title }
        _attributes = cachedAttributes
    }
    
    var cachedAttributes: TypedDict<TrackAttribute> {
        let dict = TypedDict<TrackAttribute>()
        dict[TrackAttribute.title] = title
        return dict
    }
}
