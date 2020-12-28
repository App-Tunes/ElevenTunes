//
//  DBTrack+CoreDataProperties.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 26.12.20.
//
//

import Foundation
import CoreData


extension DBTrack {

    @nonobjc public class func createFetchRequest() -> NSFetchRequest<DBTrack> {
        return NSFetchRequest<DBTrack>(entityName: "DBTrack")
    }

    @NSManaged public var backend: PersistentTrack?
    @NSManaged public var backendID: String
    @NSManaged public var title: String?
    @NSManaged public var backendCacheMask: Int16
    @NSManaged public var references: NSSet

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
