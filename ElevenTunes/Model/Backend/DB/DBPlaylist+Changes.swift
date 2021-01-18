//
//  DBPlaylist+Changes.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 27.12.20.
//

import Foundation

extension DBPlaylist: SelfChangeWatcher {
	func onUpdate(_ update: PlaylistAttributes.Update) {
		let affectedGroups = DBPlaylist.attributeGroups.any(update.change)
		
		let attributes = update.0
		let context = managedObjectContext!
		
		if affectedGroups.contains(.tracks) {
			let snapshot = attributes[PlaylistAttribute.tracks]
			let tracks = snapshot.value ?? []
			
			switch snapshot.state {
			case .version(let version):
				let old = self.tracks.array as! [DBTrack]
				let oldIDs = old.map(\.backendID)
				if indexed, oldIDs != tracks.map(\.id) {
					// TODO We might be able to use caches if we don't call asToken
					// TODO Only let it re-use old tracks
					let (dbTracks, _) = Library.convert(DirectLibrary(allTracks: tracks.map(\.asToken)), context: context)
					self.tracks = NSOrderedSet(array: dbTracks)
					Library.prune(tracks: old, context: context)
				}
				self.tracksVersion = version
			default:
				break  // TODO Handle errors etc.?
			}
		}
		
		if affectedGroups.contains(.children) {
			let snapshot = attributes[PlaylistAttribute.children]
			let children = snapshot.value ?? []
			
			switch snapshot.state {
			case .version(let version):
				let old = self.children.array as! [DBPlaylist]
				let oldIDs = old.map(\.backendID)
				if indexed, oldIDs != children.map(\.id) {
					// TODO We might be able to use caches if we don't call asToken
					// TODO Only let it re-use old playlists
					let (_, dbPlaylists) = Library.convert(DirectLibrary(allPlaylists: children.map(\.asToken)), context: context)
					self.children = NSOrderedSet(array: dbPlaylists)
					Library.prune(playlists: old, context: context)
				}
				self.childrenVersion = version
			default:
				break  // TODO Handle errors etc.?
			}
		}
		
		let nonRawAttributes: [PlaylistAttribute] = [.tracks, .children]
		let rawAttributes = update.0.filter { !nonRawAttributes.contains($0) }
		
		for attribute in update.change {
			guard let keyPath = DBPlaylist.keypathByAttribute[attribute] else {
				continue
			}
			
			// TODO How to type-safe this?
			self.setValue(rawAttributes.attributes[unsafe: attribute], forKey: keyPath)
		}
		
		if affectedGroups.contains(.attributes) {
			let group = rawAttributes.extract(DBPlaylist.attributeGroups[.attributes]!)
			switch group.state {
			case .version(let version):
				self.version = version
			default:
				// TODO Handle
				self.version = nil
				break
			}
		}
	}
	
    func onSelfChange() {
		let changes = changedValues()
		
		if changes.keys.contains("backend") {
			if let backend = backend, backend.id != backendID {
				// Invalidate stuff we stored for the backend
				backendID = backend.id
				if tracks.firstObject != nil { tracks = NSOrderedSet() }
				if children.firstObject != nil { children = NSOrderedSet() }
				childrenVersion ?= nil
				tracksVersion ?= nil
				version ?= nil
			}
			
			backendP = backend
		}

        if changes.keys.contains("indexed") {
            isIndexedP ?= indexed
        }
		
		collectUpdate(changes)
    }
	
	func collectUpdate(_ changes: [String: Any]) {
		let update = Dictionary(uniqueKeysWithValues: changes.compactMap { (name, value) in
			DBPlaylist.attributeByKeypath[name].map { ($0, value) }
		})
		
		// TODO Can we automate this somehow?
		let updateGroups = DBPlaylist.attributeGroups.any(Set(update.keys))
		
		func appropriateState(_ version: PlaylistVersion?) -> VolatileState<PlaylistVersion> {
			guard backend != nil else {
				return .version(nil)
			}
			
			return version != nil ? .version(version!) : .missing
		}
		
		var snapshot = PlaylistAttributes.Snapshot()
				
		for (group, versionKeyPath) in DBPlaylist.versionByAttribute {
			let versionKeyName = NSExpression(forKeyPath: versionKeyPath).keyPath
			if updateGroups.contains(group) || changes.keys.contains(versionKeyName) {
				let groupMembers = DBPlaylist.attributeGroups[group]!
				
				snapshot = snapshot.merging(update: VolatileAttributes.GroupSnapshot.unsafe(
					update.filter { groupMembers.contains($0.key) },
					state: appropriateState(self[keyPath: versionKeyPath])
				).explode())
			}
		}
	}
}
