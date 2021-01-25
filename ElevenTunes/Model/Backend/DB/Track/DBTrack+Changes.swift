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
		
		let nonRawAttributes: [TrackAttribute] = []
		let rawAttributes = update.0.filter { !nonRawAttributes.contains($0) }
		
		func appropriateVersion(forState state: PlaylistAttributes.State) -> PlaylistVersion? {
			switch state {
			case .version(let version):
				return version
			default:
				return nil
			}
		}

		for attribute in update.change {
			guard let keyPath = DBTrack.keypathByAttribute[attribute] else {
				continue
			}
			
			// TODO How to type-safe this?
			self.setValue(rawAttributes.attributes[unsafe: attribute], forKey: keyPath)
		}
		
		if affectedGroups.contains(.info) {
			let group = rawAttributes.extract(DBTrack.attributeGroups[.info]!)
			version ?= appropriateVersion(forState: group.state)
		}
	}
	
	func onSelfChange() {
		let changes = changedValues()
		
		if changes.keys.contains("backend") {
			if let backend = backend, backend.id != backendID {
				// Invalidate stuff we stored for the backend
				backendID = backend.id
				version ?= nil
			}
			
			backendP = backend
		}
		
		collectUpdate(changes)
	}
	
	func collectUpdate(_ changes: [String: Any]) {
		let update = Dictionary(uniqueKeysWithValues: changes.compactMap { (name, value) in
			DBTrack.attributeByKeypath[name].map { ($0, value) }
		})
		
		// TODO Can we automate this somehow?
		let updateGroups = DBTrack.attributeGroups.any(Set(update.keys))
		
		func appropriateState(_ version: TrackVersion?) -> VolatileState<TrackVersion> {
			guard backend != nil else {
				return .version(nil)
			}
			
			return version != nil ? .version(version!) : .missing
		}
		
		var snapshot = TrackAttributes.Snapshot()
				
		for (group, versionKeyPath) in DBTrack.versionByAttribute {
			let versionKeyName = NSExpression(forKeyPath: versionKeyPath).keyPath
			if updateGroups.contains(group) || changes.keys.contains(versionKeyName) {
				let groupMembers = DBTrack.attributeGroups[group]!
				
				snapshot = snapshot.merging(update: VolatileAttributes.GroupSnapshot.unsafe(
					update.filter { groupMembers.contains($0.key) },
					state: appropriateState(self[keyPath: versionKeyPath])
				).explode())
			}
		}
	}
}
