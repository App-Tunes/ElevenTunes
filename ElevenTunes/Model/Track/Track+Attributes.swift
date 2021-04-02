//
//  Track+Attributes.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 25.12.20.
//

import Foundation

public typealias TrackVersion = String

public class TrackAttribute: RawRepresentable, Hashable {
    class Typed<K>: TrackAttribute, TypedKey, CustomStringConvertible {
        typealias Value = K
        var description: String { rawValue }
    }

    public let rawValue: String
    
    public required init(rawValue: String) {
        self.rawValue = rawValue
    }
}

extension TrackAttribute {
	static let artists = Typed<[AnyArtist]>(rawValue: "artists")
	static let album = Typed<AnyAlbum>(rawValue: "album")

	static let title = Typed<String>(rawValue: "title")
	
    static let key = Typed<MusicalKey>(rawValue: "key")
	static let tempo = Typed<Tempo>(rawValue: "tempo")

	static let waveform = Typed<Waveform>(rawValue: "waveform")

	static let previewImage = Typed<NSImage>(rawValue: "previewImage")
}

public typealias TrackAttributes = VolatileAttributes<TrackAttribute, TrackVersion>
