//
//  DBSpotifyTrack+CoreDataProperties.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 25.01.21.
//
//

import Foundation
import CoreData


extension DBSpotifyTrack {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<DBSpotifyTrack> {
        return NSFetchRequest<DBSpotifyTrack>(entityName: "DBSpotifyTrack")
    }

    @NSManaged public var owner: DBTrack?
	@NSManaged public var spotifyID: String

}

extension DBSpotifyTrack : Identifiable {

}
