//
//  DBTrack+CoreDataProperties.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 25.01.21.
//
//

import Foundation
import CoreData


extension DBTrack {

	@nonobjc public class func createFetchRequest() -> NSFetchRequest<DBTrack> {
		return NSFetchRequest<DBTrack>(entityName: "DBTrack")
	}

    @NSManaged public var primaryRepresentation: Representation
    @NSManaged public var uuid: UUID
    @NSManaged public var album: DBAlbum?
    @NSManaged public var avRepresentation: DBAVTrack?
    @NSManaged public var references: NSSet
    @NSManaged public var spotifyRepresentation: DBSpotifyTrack?

}

// MARK: Generated accessors for references
extension DBTrack {

    @objc(addReferencesObject:)
    @NSManaged public func addToReferences(_ value: DBPlaylist)

    @objc(removeReferencesObject:)
    @NSManaged public func removeFromReferences(_ value: DBPlaylist)

    @objc(addReferences:)
    @NSManaged public func addToReferences(_ values: NSSet)

    @objc(removeReferences:)
    @NSManaged public func removeFromReferences(_ values: NSSet)

}

extension DBTrack : Identifiable {

}
