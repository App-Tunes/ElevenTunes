//
//  DBArtist+CoreDataProperties.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 25.01.21.
//
//

import Foundation
import CoreData


extension DBArtist {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<DBArtist> {
        return NSFetchRequest<DBArtist>(entityName: "DBArtist")
    }

    @NSManaged public var name: String?
    @NSManaged public var albums: NSSet?
    @NSManaged public var playlists: NSSet?

}

// MARK: Generated accessors for albums
extension DBArtist {

    @objc(addAlbumsObject:)
    @NSManaged public func addToAlbums(_ value: DBAlbum)

    @objc(removeAlbumsObject:)
    @NSManaged public func removeFromAlbums(_ value: DBAlbum)

    @objc(addAlbums:)
    @NSManaged public func addToAlbums(_ values: NSSet)

    @objc(removeAlbums:)
    @NSManaged public func removeFromAlbums(_ values: NSSet)

}

// MARK: Generated accessors for playlists
extension DBArtist {

    @objc(addPlaylistsObject:)
    @NSManaged public func addToPlaylists(_ value: DBPlaylist)

    @objc(removePlaylistsObject:)
    @NSManaged public func removeFromPlaylists(_ value: DBPlaylist)

    @objc(addPlaylists:)
    @NSManaged public func addToPlaylists(_ values: NSSet)

    @objc(removePlaylists:)
    @NSManaged public func removeFromPlaylists(_ values: NSSet)

}

extension DBArtist : Identifiable {

}
