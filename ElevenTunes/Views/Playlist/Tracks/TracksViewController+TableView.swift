//
//  TracksViewController+TableView.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 07.03.21.
//

import Cocoa
import SwiftUI

extension TracksViewController: NSTableViewDelegate {
	enum ColumnIdentifiers {
		static let Title = NSUserInterfaceItemIdentifier(rawValue: "Title")
		static let Image = NSUserInterfaceItemIdentifier(rawValue: "Image")
		static let Tempo = NSUserInterfaceItemIdentifier(rawValue: "Tempo")
		static let Key = NSUserInterfaceItemIdentifier(rawValue: "Key")
	}

	enum CellIdentifiers {
		static let ImageCell = NSUserInterfaceItemIdentifier(rawValue: "ImageCell")
		static let TrackCell = NSUserInterfaceItemIdentifier(rawValue: "TrackCell")
		static let TempoCell = NSUserInterfaceItemIdentifier(rawValue: "TempoCell")
		static let KeyCell = NSUserInterfaceItemIdentifier(rawValue: "KeyCell")
	}

	func initColumns() {
		tableView.tableColumns.forEach(tableView.removeTableColumn)
		
		func addColumn(_ identifier: NSUserInterfaceItemIdentifier, title: String, fun: (NSTableColumn) -> Void) {
			let column = NSTableColumn(identifier: identifier)
			column.title = title
			fun(column)
			tableView.addTableColumn(column)
		}
		
		addColumn(ColumnIdentifiers.Image, title: "⸬") {
			$0.widthRange = tableView.rowHeight...tableView.rowHeight
			$0.headerCell.alignment = .center
		}
		
		addColumn(ColumnIdentifiers.Title, title: "Title") {
			$0.widthRange = 150...CGFloat.infinity
		}
		
		addColumn(ColumnIdentifiers.Tempo, title: "♩=") {
			$0.widthRange = 52...52
			$0.headerCell.alignment = .center
		}

		addColumn(ColumnIdentifiers.Key, title: "♫") {
			$0.widthRange = 42...42
			$0.headerCell.alignment = .center
		}
	}
	
	func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
		let track = self.tracks[row]
		
		func createOn(_ identifier: NSUserInterfaceItemIdentifier, cell: NSUserInterfaceItemIdentifier) -> AnyNSHostingView? {
			if tableColumn?.identifier == identifier {
				let view = tableView.makeView(withIdentifier: cell, owner: nil) as! AnyNSHostingView
				return view
			}
			return nil
		}
		
		if let view = createOn(ColumnIdentifiers.Title, cell: CellIdentifiers.TrackCell) {
			view.rootView = AnyView(TrackCellView(track: track))
			return view
		}
		
		if let view = createOn(ColumnIdentifiers.Image, cell: CellIdentifiers.ImageCell) {
			view.rootView = AnyView(PlayTrackImageView(track: track, context: .playlist(playlist.backend, tracks: tracks.map(\.backend), index: row))
									.environment(\.library, library)
						.environment(\.player, library.player)
					)
			return view
		}

		if let view = createOn(ColumnIdentifiers.Tempo, cell: CellIdentifiers.TempoCell) {
			view.rootView = AnyView(TrackTempoView(track: track))
			return view
		}

		if let view = createOn(ColumnIdentifiers.Key, cell: CellIdentifiers.KeyCell) {
			view.rootView = AnyView(TrackKeyView(track: track))
			return view
		}
		
		return nil
	}
}

extension TracksViewController: NSTableViewDataSource {
	func numberOfRows(in tableView: NSTableView) -> Int {
		tracks.count
	}
}
