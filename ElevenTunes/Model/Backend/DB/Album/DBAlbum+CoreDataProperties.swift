//
//  DBAlbum+CoreDataProperties.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 25.01.21.
//
//

import Foundation
import CoreData


extension DBAlbum {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<DBAlbum> {
        return NSFetchRequest<DBAlbum>(entityName: "DBAlbum")
    }

    @NSManaged public var title: String?
    @NSManaged public var artists: NSOrderedSet?
    @NSManaged public var tracks: NSOrderedSet?

}

// MARK: Generated accessors for artists
extension DBAlbum {

    @objc(insertObject:inArtistsAtIndex:)
    @NSManaged public func insertIntoArtists(_ value: DBArtist, at idx: Int)

    @objc(removeObjectFromArtistsAtIndex:)
    @NSManaged public func removeFromArtists(at idx: Int)

    @objc(insertArtists:atIndexes:)
    @NSManaged public func insertIntoArtists(_ values: [DBArtist], at indexes: NSIndexSet)

    @objc(removeArtistsAtIndexes:)
    @NSManaged public func removeFromArtists(at indexes: NSIndexSet)

    @objc(replaceObjectInArtistsAtIndex:withObject:)
    @NSManaged public func replaceArtists(at idx: Int, with value: DBArtist)

    @objc(replaceArtistsAtIndexes:withArtists:)
    @NSManaged public func replaceArtists(at indexes: NSIndexSet, with values: [DBArtist])

    @objc(addArtistsObject:)
    @NSManaged public func addToArtists(_ value: DBArtist)

    @objc(removeArtistsObject:)
    @NSManaged public func removeFromArtists(_ value: DBArtist)

    @objc(addArtists:)
    @NSManaged public func addToArtists(_ values: NSOrderedSet)

    @objc(removeArtists:)
    @NSManaged public func removeFromArtists(_ values: NSOrderedSet)

}

// MARK: Generated accessors for tracks
extension DBAlbum {

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

extension DBAlbum : Identifiable {

}
