//
//  DBTrack+Changes.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 27.12.20.
//

import Foundation

extension DBTrack: SelfChangeWatcher {
	func onUpdate(_ update: TrackAttributes.Update) {
		let affectedGroups = DBTrack.attributeGroups.any(update.change)
		
		let attributes = update.0
				
		if affectedGroups.contains(.info) {
			let snapshot = attributes.extract(DBTrack.attributeGroups[.info]!)
			let attributes = snapshot.value

			switch snapshot.state {
			case .version(let version):
				for (key, value) in attributes.contents {
					let keyPath = DBTrack.keypathByAttribute[key]!
					self.setValue(value, forKey: keyPath)
				}
				self.version = version
			default:
				break  // TODO Handle errors etc.?
			}
		}
	}
	
	func onSelfChange() {
		let changes = changedValues()

		// TODO
		
		if changes.keys.contains("backend") {
			if let backend = backend, backend.id != backendID {
				// Invalidate stuff we stored for the backend
				backendID = backend.id
				version ?= nil
			}
			
			backendP = backend
		}
		
		var update = TypedDict<TrackAttribute>()
		for (key, change) in changes {
			if let attribute = DBTrack.attributeByKeypath[key] {
				// TODO Can we make this type-safe?
				update[unsafe: attribute] = change
			}
		}
		// TODO Can we automate this somehow?
		let updateGroups = DBTrack.attributeGroups.any(Set(update.keys))
		
		if updateGroups.contains(.info) || changes.keys.contains("version") {
			let state: TrackAttributes.State = version != nil ? .version(version!) : .missing
			attributes.update(update.filter(DBTrack.attributeGroups[.info]!.contains), state: state)
		}
	}
}
