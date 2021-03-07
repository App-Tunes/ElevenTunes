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
		representationsP = representations
	}
	
	var representations: [Representation: AnyTrackCache] {
		var reps: [Representation: AnyTrackCache] = [:]
		
		reps[.av] = avRepresentation
		reps[.spotify] = spotifyRepresentation

		return reps
	}
}

protocol BranchableTrack {
	@discardableResult
	func store(in track: DBTrack) throws -> DBTrack.Representation
}
