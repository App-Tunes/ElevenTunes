//
//  PlaylistsViewController+ContextMenu.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 14.02.21.
//

import Foundation

extension PlaylistsViewController: NSOutlineViewContextSensitiveMenuDelegate {
	func currentMenu(forOutlineView outlineView: NSOutlineViewContextSensitiveMenu) -> NSMenu? {
		let items = outlineView.contextualClickedRows
			.compactMap(outlineView.item)
			.map(item)
				
		return PlaylistActions(playlists: Set(items.map { Playlist($0.playlist) })).makeMenu()
	}
	
	func outlineView(_ outlineView: NSOutlineView, pasteboardWriterForItem item: Any) -> NSPasteboardWriting? {
		let item = self.item(raw: item)

		return PlaylistsExportManager(playlists: [Playlist(item.playlist)]).pasteboardItem()
	}

	func outlineView(_ outlineView: NSOutlineView, validateDrop info: NSDraggingInfo, proposedItem item: Any?, proposedChildIndex index: Int) -> NSDragOperation {
		let pasteboard = info.draggingPasteboard
		let item = self.item(raw: item)

		if pasteboard.canReadItem(withDataConformingToTypes: [PlaylistsExportManager.playlistsIdentifier]) {
			return item.playlist.contentType != .tracks ? .move : []
		}
		
		return PlaylistInterpreter.standard.interpret(pasteboard: pasteboard) != nil ? .copy : []
	}
	
	func outlineView(_ outlineView: NSOutlineView, acceptDrop info: NSDraggingInfo, item: Any?, childIndex index: Int) -> Bool {
		let pasteboard = info.draggingPasteboard
		let item = self.item(raw: item)

		let library = self.library
		
		if
			let playlists = PlaylistsExportManager.read(fromPasteboard: pasteboard, context: library.managedObjectContext),
			let playlist = item.playlist as? BranchingPlaylist,
			playlist.primary is JustCachePlaylist
		{
			// Internal cache-only drag; do internal logic
			
			playlist.cache.children = playlist.cache.children.inserting(contentsOf: playlists, atIndex: index >= 0 ? index : nil)

			return true
		}
		
		// External drag; import formally

		return PlaylistInterpreter.standard.interpret(pasteboard: pasteboard)?
			.sink(receiveCompletion: appLogErrors(_:)) { tokens in
				do {
					try item.playlist.import(library: UninterpretedLibrary(playlists: tokens), toIndex: index)
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
