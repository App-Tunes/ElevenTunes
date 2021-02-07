//
//  DBPlaylist+CoreDataProperties.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 25.01.21.
//
//

import Foundation
import CoreData


extension DBPlaylist {

	@nonobjc public class func createFetchRequest() -> NSFetchRequest<DBPlaylist> {
		return NSFetchRequest<DBPlaylist>(entityName: "DBPlaylist")
	}

	@nonobjc public class func createFetchRequest(id: UUID) -> NSFetchRequest<DBPlaylist> {
		let request = self.createFetchRequest()
		request.predicate = NSPredicate(format: "uuid = %@", id as CVarArg)
		return request
	}

    @NSManaged public var contentType: PlaylistContentType
    @NSManaged public var primaryRepresentation: Representation
    @NSManaged public var title: String?
    @NSManaged public var uuid: UUID
    @NSManaged public var artists: NSSet
    @NSManaged public var children: NSOrderedSet
    @NSManaged public var directoryRepresentation: DBDirectoryPlaylist?
    @NSManaged public var m3uRepresentation: DBM3UPlaylist?
    @NSManaged public var parent: DBPlaylist?
    @NSManaged public var spotifyRepresentation: DBSpotifyPlaylist?
    @NSManaged public var tracks: NSOrderedSet

}

// MARK: Generated accessors for artists
extension DBPlaylist {

    @objc(addArtistsObject:)
    @NSManaged public func addToArtists(_ value: DBArtist)

    @objc(removeArtistsObject:)
    @NSManaged public func removeFromArtists(_ value: DBArtist)

    @objc(addArtists:)
    @NSManaged public func addToArtists(_ values: NSSet)

    @objc(removeArtists:)
    @NSManaged public func removeFromArtists(_ values: NSSet)

}

// MARK: Generated accessors for children
extension DBPlaylist {

    @objc(insertObject:inChildrenAtIndex:)
    @NSManaged public func insertIntoChildren(_ value: DBPlaylist, at idx: Int)

    @objc(removeObjectFromChildrenAtIndex:)
    @NSManaged public func removeFromChildren(at idx: Int)

    @objc(insertChildren:atIndexes:)
    @NSManaged public func insertIntoChildren(_ values: [DBPlaylist], at indexes: NSIndexSet)

    @objc(removeChildrenAtIndexes:)
    @NSManaged public func removeFromChildren(at indexes: NSIndexSet)

    @objc(replaceObjectInChildrenAtIndex:withObject:)
    @NSManaged public func replaceChildren(at idx: Int, with value: DBPlaylist)

    @objc(replaceChildrenAtIndexes:withChildren:)
    @NSManaged public func replaceChildren(at indexes: NSIndexSet, with values: [DBPlaylist])

    @objc(addChildrenObject:)
    @NSManaged public func addToChildren(_ value: DBPlaylist)

    @objc(removeChildrenObject:)
    @NSManaged public func removeFromChildren(_ value: DBPlaylist)

    @objc(addChildren:)
    @NSManaged public func addToChildren(_ values: NSOrderedSet)

    @objc(removeChildren:)
    @NSManaged public func removeFromChildren(_ values: NSOrderedSet)

}

// MARK: Generated accessors for tracks
extension DBPlaylist {

    @objc(insertObject:inTracksAtIndex:)
    @NSManaged public func insertIntoTracks(_ value: DBTrack, at idx: Int)

    @objc(removeObjectFromTracksAtIndex:)
    @NSManaged public func removeFromTracks(at idx: Int)

    @objc(insertTracks:atIndexes:)
    @NSManaged public func insertIntoTracks(_ values: [DBTrack], at indexes: NSIndexSet)

    @objc(removeTracksAtIndexes:)
    @NSManaged public func removeFromTracks(at indexes: NSIndexSet)

    @objc(replaceObjectInTracksAtIndex:withObject:)
    @NSManaged public func replaceTracks(at idx: Int, with value: DBTrack)

    @objc(replaceTracksAtIndexes:withTracks:)
    @NSManaged public func replaceTracks(at indexes: NSIndexSet, with values: [DBTrack])

    @objc(addTracksObject:)
    @NSManaged public func addToTracks(_ value: DBTrack)

    @objc(removeTracksObject:)
    @NSManaged public func removeFromTracks(_ value: DBTrack)

    @objc(addTracks:)
    @NSManaged public func addToTracks(_ values: NSOrderedSet)

    @objc(removeTracks:)
    @NSManaged public func removeFromTracks(_ values: NSOrderedSet)

}

extension DBPlaylist : Identifiable {

}
