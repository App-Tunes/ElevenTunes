//
//  DBAVTrack+CoreDataProperties.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 25.01.21.
//
//

import Foundation
import CoreData


extension DBAVTrack {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<DBAVTrack> {
        return NSFetchRequest<DBAVTrack>(entityName: "DBAVTrack")
    }

    @NSManaged public var isVideo: Bool
	@NSManaged public var url: URL
	@NSManaged public var metadata: DBFileMetadata?
    @NSManaged public var owner: DBTrack

}

extension DBAVTrack : Identifiable {

}
