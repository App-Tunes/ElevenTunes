//
//  DBM3UPlaylist+CoreDataProperties.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 25.01.21.
//
//

import Foundation
import CoreData


extension DBM3UPlaylist {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<DBM3UPlaylist> {
        return NSFetchRequest<DBM3UPlaylist>(entityName: "DBM3UPlaylist")
    }

    @NSManaged public var fileChangedDate: Date?
	@NSManaged public var url: URL
    @NSManaged public var owner: DBPlaylist?

}

extension DBM3UPlaylist : Identifiable {

}
