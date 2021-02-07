//
//  DBM3UPlaylist+CoreDataClass.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 25.01.21.
//
//

import Foundation
import CoreData

@objc(DBM3UPlaylist)
public class DBM3UPlaylist: NSManagedObject {

}

extension DBM3UPlaylist: AnyPlaylistCache {
	public func expand(library: Library) -> AnyPlaylist {
		M3UPlaylist(url, library: library)
	}
}
