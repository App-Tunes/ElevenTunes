//
//  PlaylistsViewController+Interaction.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 07.03.21.
//

import Cocoa

extension PlaylistsViewController {
	@IBAction func didDoubleClick(_ sender: Any) {
		guard let clicked = outlineView.clickedRow.positiveOrNil else {
			return
		}

		let item = outlineView.item(atRow: clicked) as! Item
		
		guard !self.outlineView(outlineView, isItemExpandable: item) else {
			outlineView.toggleItemExpanded(item)
			return
		}
		
//		if let playlist = item.asPlaylist {
//			PlaylistActions.create(.visible(playlists: [playlist]))?.menuPlay(self)
//			return
//		}
	}
}
