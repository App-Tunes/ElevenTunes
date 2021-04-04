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
	let algorithms: [(String, [TrackAlgorithm])]

	init(tracks: Set<Track>) {
		self.tracks = tracks
		algorithms = TrackAlgorithms.for(tracks.map(\.backend))
	}

	convenience init(track: Track, selection: Set<Track>) {
		self.init(tracks: selection.allIfContains(track))
	}

	convenience init(tracks: [Track], idx: Int, selected: Set<Int>) {
        let sindices = selected.allIfContains(idx)
		self.init(tracks: Set(sindices.map { tracks[$0] }))
    }
        
    func callAsFunction() -> some View {
        VStack {
			let tracks = self.tracks

            Button(action: reloadMetadata) {
                Text("Reload Metadata")
            }

			if let track = tracks.one, let origin = track.backend.origin {
                Button(action: {
					NSWorkspace.shared.visit(origin)
                }) {
                    Text("Visit Origin")
                }
            }
			
			if let algorithms = algorithms.nonEmpty {
				Menu("Analyze...") {
					ForEach(algorithms, id: \.0) { (name, algorithm) in
						Button(action: {
							TrackAlgorithms.run(algorithm)
						}) {
							Text(name)
						}
						.disabled(true)
					}
				}
			}
			
			if tracks.map(\.backend) as? [BranchingTrack] != nil{
				Button(action: unlink) {
					Text("Remove from Library")
				}
			}

			if tracks.allSatisfy({ $0.backend.supports(.delete) }) {
				Button(action: delete) {
					Text("Delete")
				}
			}
        }
    }
	
	func makeMenu() -> NSMenu {
		guard !tracks.isEmpty else {
			return NSMenu()
		}
		
		let menu = StaticMenu()
		
		menu.addItem(withTitle: "Reload Metadata", callback: self.reloadMetadata)

		if let track = tracks.one, let origin = track.backend.origin {
			menu.addItem(withTitle: "Visit Origin") {
				NSWorkspace.shared.visit(origin)
			}
		}
		
		if !algorithms.isEmpty {
			let algorithmsMenu = menu.addSubmenu(withTitle: "Analyze...")
			for (name, algorithm) in algorithms {
				algorithmsMenu.addItem(withTitle: name, disabled: true) {
					TrackAlgorithms.run(algorithm)
				}
			}
		}
		
		if tracks.map(\.backend) as? [BranchingTrack] != nil{
			menu.addItem(withTitle: "Remove from library", callback: unlink)
		}
		
		if tracks.allSatisfy({ $0.backend.supports(.delete) }) {
			menu.addItem(withTitle: "Delete", callback: delete)
		}

		return menu.menu
	}
	
	func reloadMetadata() {
		tracks.forEach { $0.backend.invalidateCaches() }
	}
	
	func delete() {
		do {
			try tracks.forEach {
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
		tracks.forEach {
			($0.backend as? BranchingTrack)?.cache.delete()
		}
	}
}
