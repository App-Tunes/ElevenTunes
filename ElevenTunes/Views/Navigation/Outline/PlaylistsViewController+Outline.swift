//
//  PlaylistsViewController+Outline.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 14.02.21.
//

import Foundation
import SwiftUI

extension PlaylistsViewController: NSOutlineViewDelegate {
	enum CellIdentifiers {
		static let HeaderCell = NSUserInterfaceItemIdentifier(rawValue: "HeaderCell")
		static let DataCell = NSUserInterfaceItemIdentifier(rawValue: "DataCell")
		static let PlaylistCell = NSUserInterfaceItemIdentifier(rawValue: "PlaylistCell")
	}

	func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item raw: Any) -> NSView? {
		let item = self.item(raw: raw)
		let playlist = item.playlist
		let isTopLevel = item.parent == directoryItem
		
//		if let view = outlineView.makeView(withIdentifier: isTopLevel ? CellIdentifiers.HeaderCell : CellIdentifiers.DataCell, owner: nil) as? NSTableCellViewAttachedObject {
//
//			view.imageView?.image = NSImage(systemSymbolName: "gear", accessibilityDescription: "Gear")
//
//			view.representedObject = (
//				playlist.demand([PlaylistAttribute.title]),
//				playlist.attribute(PlaylistAttribute.title).sink { [weak view] snapshot in
//					view?.textField?.stringValue = snapshot.value ?? ""
//				}
//			)
//
//			return view
//		}
		
		if let view = outlineView.makeView(withIdentifier: CellIdentifiers.PlaylistCell, owner: nil) as? AnyNSHostingView {
			view.rootView = AnyView(PlaylistRowView(playlist: Playlist(playlist), isTopLevel: isTopLevel))
			return view
		}


		return nil
	}
	
	func outlineView(_ outlineView: NSOutlineView, isGroupItem raw: Any) -> Bool {
		item(raw: raw).parent == directoryItem
	}
	
	func outlineViewItemDidExpand(_ notification: Notification) {
		let item = self.item(raw: notification.userInfo!["NSObject"]!)
		item.isDemanding = true
	}
	
	func outlineViewItemDidCollapse(_ notification: Notification) {
		let item = self.item(raw: notification.userInfo!["NSObject"]!)
		item.isDemanding = false
	}
	
	func outlineViewSelectionDidChange(_ notification: Notification) {
		let items = outlineView.selectedRowIndexes
			.map { outlineView.item(atRow: $0) as! Item }
		
		var insertPosition: (Playlist, Int?)? = nil
		if let item = items.one {
			if item.playlist.contentType == .tracks {
				insertPosition = (Playlist(item.parent!.playlist), outlineView.childIndex(forItem: item) + 1)
			}
			else {
				insertPosition = (Playlist(item.playlist), nil)
			}
		}
		navigator.select(.init(insertPosition: insertPosition, items: Set(items.map { Playlist($0.playlist) })))
	}
	
	func outlineView(_ outlineView: NSOutlineView, shouldTypeSelectFor event: NSEvent, withCurrentSearch searchString: String?) -> Bool {
		// Needs a solid implementatin on our side, since subviews are hosting views
		false
	}
	
	func outlineView(_ outlineView: NSOutlineView, willDisplayOutlineCell cell: Any, for tableColumn: NSTableColumn?, item: Any) {
		expandExtension.willDisplayItem(item, withID: (item as! Item).playlist.id)
	}
	
	func observeNavigator() {
		let navigator = self.navigator

		// OnMain so we are in objectDidChange
		navigationObservation = navigator.objectWillChange.onMain().sink { [weak self] in
			guard let self = self, let outlineView = self.outlineView else { return }
			
			// Suboptimal, but navigator.row(forItem) uses === checking. We can't lookup items.
			let selected = self.indices(forPlaylists: navigator.selection.items)
			
			if selected != outlineView.selectedRowIndexes {
				outlineView.selectRowIndexes(selected, byExtendingSelection: false)
			}
		}
	}
}

extension PlaylistsViewController: NSOutlineViewDataSource {
	func item(raw: Any?) -> Item {
		return raw != nil ? (raw as! Item) : directoryItem
	}
	
	func item(forPlaylistID id: String) -> Item? {
		IndexSet(0..<outlineView.numberOfRows)
			.map { outlineView.item(atRow: $0) as! Item }
			.first {
				$0.playlist.id == id
			}
	}
	
	func item(forCache playlist: DBPlaylist) -> Item? {
		IndexSet(0..<outlineView.numberOfRows)
			.map { outlineView.item(atRow: $0) as! Item }
			.first {
				($0.playlist as? BranchingPlaylist)?.cache == playlist
			}
	}
	
	func indices<C>(forPlaylists playlists: C) -> IndexSet where C: Collection, C.Element == Playlist {
		let ids = playlists.map(\.id)
		return IndexSet(IndexSet(0..<outlineView.numberOfRows)
			.filter {
				ids.contains((outlineView.item(atRow: $0) as! Item).playlist.id)
			}
		)
	}
	
	func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem raw: Any?) -> Int {
		item(raw: raw).childrenState.value?.count ?? 0
	}
	
	func outlineView(_ outlineView: NSOutlineView, isItemExpandable raw: Any) -> Bool {
		item(raw: raw).playlist.contentType != .tracks
	}
	
	func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem raw: Any?) -> Any {
		item(raw: raw).childrenState.value?[safe: index] ?? dummyPlaylist!
	}
	
	func outlineView(_ outlineView: NSOutlineView, objectValueFor tableColumn: NSTableColumn?, byItem raw: Any?) -> Any? {
		nil
	}
	
	func outlineView(_ outlineView: NSOutlineView, persistentObjectForItem item: Any?) -> Any? {
		self.item(raw: item).playlist.id
	}
	
	func outlineView(_ outlineView: NSOutlineView, itemForPersistentObject object: Any) -> Any? {
		// TODO Will only work if it's in view already...
		(object as? String).flatMap { item(forPlaylistID: $0) }
	}
}
