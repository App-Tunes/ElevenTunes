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

class PlaylistsContextMenu {
	let playlists: Set<Playlist>
	
	init(playlist: Playlist, selection: Set<Playlist>) {
		self.playlists = selection.allIfContains(playlist)
	}

    func callAsFunction() -> some View {
        VStack {
			let playlists = self.playlists
			
			if playlists.contains(where: \.backend.hasCaches) {
                Button(action: {
					playlists.forEach { $0.backend.invalidateCaches() }
                }) {
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
			}) {
				Image(systemName: "minus.circle")
				Text("Delete")
			}
        }
    }
}
