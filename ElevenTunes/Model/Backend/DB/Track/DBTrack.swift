//
//  DBTrack+CoreDataClass.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 26.12.20.
//
//

import Foundation
import CoreData

@objc(DBTrack)
public class DBTrack: NSManagedObject {
    @Published var backendP: TrackToken?
    
	let attributes: VolatileAttributes<TrackAttribute, TrackVersion> = .init()

    public override func awakeFromFetch() { initialSetup() }
    public override func awakeFromInsert() { initialSetup() }

    func initialSetup() {
        backendP = backend
        
		// TODO
//		initialize content
    }
}
