//
//  Navigator.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 14.03.21.
//

import Foundation

struct ContextualSelection<T: Hashable> {
	var insertPosition: (T, Int?)?
	var items: Set<T>
	
	static var empty: ContextualSelection {
		.init(insertPosition: nil, items: [])
	}
}

class Navigator: ObservableObject {
	let root: Playlist
	
	@Published private(set) var selection: ContextualSelection<Playlist> = .empty
	
	init(root: Playlist) {
		self.root = root
		selectRoot()
	}
	
	var playlists: [Playlist] {
		selection.items.sorted { $0.id < $1.id }
	}
	
	var isRootSelected: Bool { selection.items == [root] }
	
	func selectRoot() {
		selection = .init(insertPosition: (root, nil), items: [root])
	}
	
	func select(_ selection: ContextualSelection<Playlist>) {
		if selection.items.isEmpty {
			selectRoot()
		}
		else {
			self.selection = selection
		}
	}
}
