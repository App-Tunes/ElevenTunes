//
//  DBPlaylist+CoreDataProperties.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 26.12.20.
//
//

import Foundation
import CoreData


extension DBPlaylist {

    @nonobjc public class func createFetchRequest() -> NSFetchRequest<DBPlaylist> {
        return NSFetchRequest<DBPlaylist>(entityName: "DBPlaylist")
    }

//    @NSManaged public var backend: PersistentPlaylist?
    @objc public var backend: PersistentPlaylist? {
        set {
            willChangeValue(forKey: "backend")
            setPrimitiveValue(newValue, forKey: "backend")
            didChangeValue(forKey: "backend")
            refreshObservation()
        }
        get {
            willAccessValue(forKey: "backend")
            let value = primitiveValue(forKey: "backend") as? PersistentPlaylist
            didAccessValue(forKey: "backend")
            return value
        }
    }

    
    @NSManaged public var indexed: Bool
    @NSManaged public var cachedLoadLevel: Int16
    @NSManaged public var title: String?
    @NSManaged public var children: NSOrderedSet
    @NSManaged public var parent: DBPlaylist?
    @NSManaged public var tracks: NSOrderedSet

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
