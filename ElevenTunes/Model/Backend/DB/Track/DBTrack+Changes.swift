//
//  DBTrack+Changes.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 07.03.21.
//

import CoreData

extension DBTrack: SelfChangeWatcher {
	func onSelfChange() {
		let changed = changedValues()
		
		if changed.keys.contains("primaryRepresentation") {
			primaryRepresentationP = primaryRepresentation
		}
		
		if !Set(changed.keys).isDisjoint(with: [
			"spotifyRepresentation", "avRepresentation"
		]) {
			representationsP = representations
		}
	}
}
