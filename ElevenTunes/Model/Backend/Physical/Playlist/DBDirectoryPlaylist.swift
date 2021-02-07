//
//  DBDirectoryPlaylist+CoreDataClass.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 25.01.21.
//
//

import Foundation
import CoreData

@objc(DBDirectoryPlaylist)
public class DBDirectoryPlaylist: NSManagedObject {

}

extension DBDirectoryPlaylist: AnyPlaylistCache {
	public func expand(library: Library) -> AnyPlaylist {
		DirectoryPlaylist(url, library: library)
	}
}
