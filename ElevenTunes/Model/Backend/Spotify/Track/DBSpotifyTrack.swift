//
//  DBSpotifyTrack+CoreDataClass.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 25.01.21.
//
//

import Foundation
import CoreData

@objc(DBSpotifyTrack)
public class DBSpotifyTrack: NSManagedObject {

}

extension DBSpotifyTrack: AnyTrackCache {
	public func expand(library: Library) -> AnyTrack {
		SpotifyTrack(.init(spotifyID), spotify: library.spotify)
	}
}
