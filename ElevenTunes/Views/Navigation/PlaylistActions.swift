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
                    Image(systemName: "arrow.clockwise")
                    Text("Reload Metadata")
                }
            }
			
			if let playlist = playlists.one, let origin = playlist.backend.origin {
				Button(action: {
					NSWorkspace.shared.open(origin)
				}) {
					Image(systemName: "link")
					Text("Visit Origin")
				}
			}
			
			Button(action: {
				self.deletePlaylists()
			}) {
				Image(systemName: "minus.circle")
				Text("Delete")
			}
        }
    }
	
	func makeMenu() -> NSMenu {
		let menu = StaticMenu()
		
		if playlists.contains(where: \.backend.hasCaches) {
			menu.addItem(withTitle: "Reload Metadata", callback: self.reloadMetadata)
		}

		if let playlist = playlists.one, let origin = playlist.backend.origin {
			menu.addItem(withTitle: "Visit Origin") {
				NSWorkspace.shared.open(origin)
			}
		}
		
		menu.addItem(withTitle: "Delete", callback: deletePlaylists)
				
		return menu.menu
	}
	
	func reloadMetadata() {
		playlists.forEach { $0.backend.invalidateCaches() }
	}
	
	func openOrigin(_ origin: URL) {
		NSWorkspace.shared.open(origin)
	}
	
	func deletePlaylists() {
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
}

extension PlaylistActions: NSMenuDelegate, NSMenuItemValidation {
	func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
		true
	}
}
