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

		return PlaylistsExportManager(playlists: [Playlist(item.playlist)])
	}

	func outlineView(_ outlineView: NSOutlineView, validateDrop info: NSDraggingInfo, proposedItem item: Any?, proposedChildIndex index: Int) -> NSDragOperation {
		let pasteboard = info.draggingPasteboard
		let item = self.item(raw: item)

		if pasteboard.canReadItem(withDataConformingToTypes: [PlaylistsExportManager.playlistsIdentifier]) {
			return item.playlist.contentType != .tracks ? .move : []
		}
		
		return library.interpreter.canInterpret(pasteboard: pasteboard) ? .copy : []
	}
	
	func outlineView(_ outlineView: NSOutlineView, acceptDrop info: NSDraggingInfo, item: Any?, childIndex index: Int) -> Bool {
		let pasteboard = info.draggingPasteboard
		let item = self.item(raw: item)

		if let playlists = PlaylistsExportManager.read(fromPasteboard: pasteboard, context: library.managedObjectContext) {
			guard let parent = playlists.explodeMap({ $0.parent })?.one else {
				return false  // TODO Multiple sources, can't simply rearrange
			}
			
			guard let indices = playlists.explodeMap({ parent.children.index(of: $0) }) else {
				return false // TODO Somehow playlists not in parent?
			}
			
			parent.children = parent.children.moving(fromOffsets: IndexSet(indices), toOffset: index)
			
			return true
		}

		return library.interpreter.interpret(pasteboard: pasteboard)?
			.map(ContentInterpreter.collect)
			.sink(receiveCompletion: appLogErrors(_:)) { library in
				do {
					try item.playlist.import(library: library)
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
