//
//  DBSpotifyPlaylist+CoreDataClass.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 25.01.21.
//
//

import Foundation
import CoreData

@objc(DBSpotifyPlaylist)
public class DBSpotifyPlaylist: NSManagedObject {

}

extension DBSpotifyPlaylist: AnyPlaylistCache {
	public func expand(library: Library) -> AnyPlaylist {
		SpotifyPlaylist(.init(spotifyID), spotify: library.spotify)
	}
}
