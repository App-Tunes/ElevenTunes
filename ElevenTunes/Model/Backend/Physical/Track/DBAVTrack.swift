//
//  DBAVTrack+CoreDataClass.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 25.01.21.
//
//

import Foundation
import CoreData

@objc(DBAVTrack)
public class DBAVTrack: NSManagedObject {

}

extension DBAVTrack: AnyTrackCache {
	public func expand(library: Library) -> AnyTrack {
		AVTrack(url, isVideo: isVideo)
	}
}
