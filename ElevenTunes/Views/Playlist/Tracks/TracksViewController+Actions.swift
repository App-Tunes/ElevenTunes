//
//  TracksViewController+Actions.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 07.03.21.
//

import Cocoa

extension TracksViewController: NSTableViewContextSensitiveMenuDelegate {
	@IBAction func didDoubleClick(_ sender: Any) {
		guard
			let clicked = tableView.clickedRow.positiveOrNil,
			let track = tracks[safe: clicked]
		else {
			return
		}

		library.player.play(.init(context: .playlist(playlist.backend, tracks: tracks.map(\.backend), track: track.backend)))
	}
	
	func currentMenu(forTableView tableView: NSTableViewContextSensitiveMenu) -> NSMenu? {
		let tracks = tableView.contextualClickedRows
			.compactMap { self.tracks[safe: $0] }
		
		return TrackActions(tracks: Set(tracks)).makeMenu()
	}
}
