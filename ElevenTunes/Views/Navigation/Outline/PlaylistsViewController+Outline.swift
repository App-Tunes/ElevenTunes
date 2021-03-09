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
		let isTopLevel = item.parent == directoryItem
		
		if let view = outlineView.makeView(withIdentifier: CellIdentifiers.PlaylistCell, owner: nil) as? AnyNSHostingView {
			view.rootView = AnyView(PlaylistRowView(playlist: Playlist(item.playlist), isTopLevel: isTopLevel))
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
		selectionObserver(.init(insertPosition: insertPosition, playlists: Set(items.map { Playlist($0.playlist) })))
	}	
}

extension PlaylistsViewController: NSOutlineViewDataSource {
	func item(raw: Any?) -> Item {
		return raw != nil ? (raw as! Item) : directoryItem
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
}
