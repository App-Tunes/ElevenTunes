//
//  TracksContextMenu.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 31.12.20.
//

import Foundation
import SwiftUI
import AppKit

class TrackActions: NSObject {
	let tracks: Set<Track>

	init(tracks: Set<Track>) {
		self.tracks = tracks
	}

	init(track: Track, selection: Set<Track>) {
		self.tracks = selection.allIfContains(track)
	}

    init(tracks: [Track], idx: Int, selected: Set<Int>) {
        let sindices = selected.allIfContains(idx)
		self.tracks = Set(sindices.map { tracks[$0] })
    }
        
    func callAsFunction() -> some View {
        VStack {
			let tracks = self.tracks

            Button(action: reloadMetadata) {
                Image(systemName: "arrow.clockwise")
                Text("Reload Metadata")
            }

			if let track = tracks.one, let origin = track.backend.origin {
                Button(action: {
                    NSWorkspace.shared.open(origin)
                }) {
                    Image(systemName: "link")
                    Text("Visit Origin")
                }
            }
			
			if tracks.allSatisfy({ $0.backend.primary is JustCacheTrack }) {
				Button(action: delete) {
					Image(systemName: "delete.right")
					Text("Remove from Library")
				}
			}
        }
    }
	
	func makeMenu() -> NSMenu {
		let menu = StaticMenu()
		
		menu.addItem(withTitle: "Reload Metadata", callback: self.reloadMetadata)

		if let track = tracks.one, let origin = track.backend.origin {
			menu.addItem(withTitle: "Visit Origin") {
				NSWorkspace.shared.open(origin)
			}
		}
		
		if tracks.allSatisfy({ $0.backend is BranchingTrack }) {
			menu.addItem(withTitle: "Remove from Library", callback: delete)
		}
				
		return menu.menu
	}
	
	func reloadMetadata() {
		tracks.forEach { $0.backend.invalidateCaches() }
	}
	
	func delete() {
		let tracks = self.tracks.compactMap { $0.backend as? BranchingTrack }
		tracks.forEach {
			$0.cache.managedObjectContext?.delete($0.cache)
		}
	}
}
