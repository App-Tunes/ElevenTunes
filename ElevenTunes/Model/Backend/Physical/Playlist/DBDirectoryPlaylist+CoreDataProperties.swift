//
//  DBDirectoryPlaylist+CoreDataProperties.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 25.01.21.
//
//

import Foundation
import CoreData


extension DBDirectoryPlaylist {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<DBDirectoryPlaylist> {
        return NSFetchRequest<DBDirectoryPlaylist>(entityName: "DBDirectoryPlaylist")
    }

    @NSManaged public var fileChangedDate: Date?
	@NSManaged public var url: URL
    @NSManaged public var owner: DBPlaylist?

}

extension DBDirectoryPlaylist : Identifiable {

}
