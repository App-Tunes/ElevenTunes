//
//  PlaylistsContextMenu.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 31.12.20.
//

import Foundation

import Foundation
import SwiftUI
import AppKit

class PlaylistActions: NSObject {
	let playlists: Set<Playlist>

	init(playlists: Set<Playlist>) {
		self.playlists = playlists
	}

	init(playlist: Playlist, selection: Set<Playlist>) {
		self.playlists = selection.allIfContains(playlist)
	}

    func callAsFunction() -> some View {
        VStack {
			let playlists = self.playlists
			
			if playlists.contains(where: \.backend.hasCaches) {
				Button(action: { self.reloadMetadata() }) {
                    Text("Reload Metadata")
                }
            }
			
			if let playlist = playlists.one, let origin = playlist.backend.origin {
				Button(action: {
					NSWorkspace.shared.visit(origin)
				}) {
					Text("Visit Origin")
				}
			}
			
			if playlists.map(\.backend) as? [BranchingPlaylist] != nil {
				Button(action: delete) {
					Text("Delete")
				}
			}
			
			if playlists.allSatisfy({ $0.backend.supports(.delete) }) {
				Button(action: unlink) {
					Text("Remove from Library")
				}
			}
        }
    }
	
	func makeMenu() -> NSMenu {
		guard !playlists.isEmpty else {
			return NSMenu()
		}

		let menu = StaticMenu()
		
		if playlists.contains(where: \.backend.hasCaches) {
			menu.addItem(withTitle: "Reload Metadata", callback: self.reloadMetadata)
		}

		if let playlist = playlists.one, let origin = playlist.backend.origin {
			menu.addItem(withTitle: "Visit Origin") {
				NSWorkspace.shared.visit(origin)
			}
		}
		
		if playlists.map(\.backend) as? [BranchingPlaylist] != nil{
			menu.addItem(withTitle: "Remove from library", callback: unlink)
		}
		
		if playlists.allSatisfy({ $0.backend.supports(.delete) }) {
			menu.addItem(withTitle: "Delete", callback: delete)
		}
				
		return menu.menu
	}
	
	func reloadMetadata() {
		playlists.forEach { $0.backend.invalidateCaches() }
	}
	
	func delete() {
		do {
			try playlists.forEach {
				try $0.backend.delete()
			}
		}
		catch let error {
			NSAlert.warning(
				title: "Failed to delete playlist",
				text: String(describing: error)
			)
		}
	}

	func unlink() {
		playlists.forEach {
			($0.backend as? BranchingPlaylist)?.cache.delete()
		}
	}
}

extension PlaylistActions: NSMenuDelegate, NSMenuItemValidation {
	func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
		true
	}
}
