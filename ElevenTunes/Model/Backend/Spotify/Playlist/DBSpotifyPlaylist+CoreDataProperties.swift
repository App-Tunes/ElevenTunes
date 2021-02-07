//
//  DBSpotifyPlaylist+CoreDataProperties.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 25.01.21.
//
//

import Foundation
import CoreData


extension DBSpotifyPlaylist {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<DBSpotifyPlaylist> {
        return NSFetchRequest<DBSpotifyPlaylist>(entityName: "DBSpotifyPlaylist")
    }

	@NSManaged public var spotifyID: String
    @NSManaged public var snapshotID: String?
    @NSManaged public var owner: DBPlaylist?

}

extension DBSpotifyPlaylist : Identifiable {

}
