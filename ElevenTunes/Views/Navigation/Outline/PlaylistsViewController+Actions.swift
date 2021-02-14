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
	
//	func outlineView(_ outlineView: NSOutlineView, pasteboardWriterForItem item: Any) -> NSPasteboardWriting? {
//		return (item as? Item)?.asPlaylist.map(Library.shared.export().pasteboardItem)
//	}

	func outlineView(_ outlineView: NSOutlineView, validateDrop info: NSDraggingInfo, proposedItem item: Any?, proposedChildIndex index: Int) -> NSDragOperation {
		let pasteboard = info.draggingPasteboard

		return library.interpreter.canInterpret(pasteboard: pasteboard) ? .copy : []
	}
	
	func outlineView(_ outlineView: NSOutlineView, acceptDrop info: NSDraggingInfo, item: Any?, childIndex index: Int) -> Bool {
		let pasteboard = info.draggingPasteboard
		let item = self.item(raw: item)

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
