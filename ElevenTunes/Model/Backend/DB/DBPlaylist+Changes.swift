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
		
		if affectedGroups.contains(.attributes) {
			let snapshot = attributes.extract(DBPlaylist.attributeGroups[.attributes]!)

			switch snapshot.state {
			case .version(let version):
				unpack(update: snapshot.value)
				self.version = version
			default:
				break  // TODO Handle errors etc.?
			}
		}
	}
	
	func unpack(update: TypedDict<PlaylistAttribute>) {
		for (key, value) in update.contents {
			let keyPath = DBPlaylist.keypathByAttribute[key]!
			self.setValue(value, forKey: keyPath)
		}
	}
	
    func onSelfChange() {
        let changes = changedValues()

		// TODO
        
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
        
		var update = TypedDict<PlaylistAttribute>()
		for (key, change) in changes {
			if let attribute = DBPlaylist.attributeByKeypath[key] {
				// TODO Can we make this type-safe?
				update[unsafe: attribute] = change
			}
		}
		// TODO Can we automate this somehow?
		let updateGroups = DBPlaylist.attributeGroups.any(Set(update.keys))
		
		if updateGroups.contains(.tracks) || changes.keys.contains("tracksVersion") {
			let state: PlaylistAttributes.State = tracksVersion != nil ? .version(tracksVersion!) : .missing
			attributes.update(update.filter(DBPlaylist.attributeGroups[.tracks]!.contains), state: state)
		}
		if updateGroups.contains(.children) || changes.keys.contains("childrenVersion") {
			let state: PlaylistAttributes.State = childrenVersion != nil ? .version(childrenVersion!) : .missing
			attributes.update(update.filter(DBPlaylist.attributeGroups[.children]!.contains), state: state)
		}
		if updateGroups.contains(.attributes) || changes.keys.contains("version") {
			let state: PlaylistAttributes.State = version != nil ? .version(version!) : .missing
			attributes.update(update.filter(DBPlaylist.attributeGroups[.attributes]!.contains), state: state)
		}

        if changes.keys.contains("indexed") {
            isIndexedP ?= indexed
        }
    }
}
