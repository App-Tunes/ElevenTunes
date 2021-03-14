//
//  TracksViewController+Actions.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 07.03.21.
//

import Cocoa

extension TracksViewController: NSTableViewContextSensitiveMenuDelegate {
	@IBAction func didDoubleClick(_ sender: Any) {
		tableView.clickedRow.positiveOrNil.map {
			play(rows: IndexSet([$0]))
		}
	}
	
	@IBAction func didPressReturn(_ sender: Any) {
		play(rows: tableView.selectedRowIndexes)
	}
	
	func play(rows: IndexSet) {
		guard
			let tracks = rows.explodeMap({ tracks[safe: $0] }),
			// TODO enqueue all selected tracks, not just one
			let track = tracks.one
		else {
			return
		}

		library.player.play(.init(context: .playlist(playlist.backend, tracks: self.tracks.map(\.backend), track: track.backend)))
	}
	
	func currentMenu(forTableView tableView: NSTableViewContextSensitiveMenu) -> NSMenu? {
		let tracks = tableView.contextualClickedRows
			.compactMap { self.tracks[safe: $0] }
		
		return TrackActions(tracks: Set(tracks)).makeMenu()
	}
	
	func tableView(_ tableView: NSTableView, pasteboardWriterForRow row: Int) -> NSPasteboardWriting? {
		guard let track = self.tracks[safe: row] else {
			return nil
		}

		return TracksExportManager(track: track.backend).pasteboardItem()
	}
	
	func tableView(_ tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableView.DropOperation) -> NSDragOperation {
		guard dropOperation != .on else {
			return []
		}
		
		let pasteboard = info.draggingPasteboard
		
		if pasteboard.canReadItem(withDataConformingToTypes: [TracksExportManager.tracksIdentifier]), playlist.backend is JustCachePlaylist {
			return .move
		}
		
		if
			playlist.backend.contentType != .playlists,
			playlist.backend.supports(.importChildren),
			TrackInterpreter.standard.interpret(pasteboard: pasteboard) != nil
		{
			// Found external drag
			return .move
		}
		
		return []
	}
	
	func tableView(_ tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int, dropOperation: NSTableView.DropOperation) -> Bool {
		let pasteboard = info.draggingPasteboard

		let library = self.library
		let playlist = self.playlist.backend
		
		if
			let tracks = TracksExportManager.read(fromPasteboard: pasteboard, context: library.managedObjectContext),
			let playlist = playlist.primary as? JustCachePlaylist
		{
			// Internal cache-only drag; do internal logic
			
			playlist.cache.tracks = playlist.cache.tracks.inserting(contentsOf: tracks, atIndex: row.positiveOrNil)

			return true
		}
		
		// External drag; import formally

		return TrackInterpreter.standard.interpret(pasteboard: pasteboard)?
			.sink(receiveCompletion: appLogErrors(_:)) { tokens in
				do {
					try playlist.import(library: UninterpretedLibrary(tracks: tokens), toIndex: row)
				}
				catch let error {
					NSAlert.warning(
						title: "Import Failure",
						text: String(describing: error)
					)
				}
			}
			.store(in: &cancellables) != nil
	}
}
