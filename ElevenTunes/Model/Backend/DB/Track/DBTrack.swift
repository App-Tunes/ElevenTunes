//
//  DBTrack+CoreDataClass.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 25.01.21.
//
//

import Foundation
import CoreData

@objc(DBTrack)
public class DBTrack: NSManagedObject {
	@objc public enum Representation: Int16 {
		case none, av, spotify
	}

	public let attributes = TrackAttributes()
	
	@Published public var primaryRepresentationP: Representation = .none
	@Published public var representationsP: [Representation: AnyTrackCache] = [:]
	
	public override func awakeFromFetch() { initialSetup() }
	public override func awakeFromInsert() { initialSetup() }
	
	func initialSetup() {
		primaryRepresentationP = primaryRepresentation

		representationsP[.av] = avRepresentation
		representationsP[.spotify] = spotifyRepresentation
	}
}

protocol BranchableTrack {
	@discardableResult
	func store(in playlist: DBTrack) throws -> DBTrack.Representation
}
