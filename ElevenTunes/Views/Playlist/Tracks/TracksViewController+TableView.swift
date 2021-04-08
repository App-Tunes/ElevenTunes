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
		static let Artists = NSUserInterfaceItemIdentifier(rawValue: "Artists")
		static let Album = NSUserInterfaceItemIdentifier(rawValue: "Album")
		static let Genre = NSUserInterfaceItemIdentifier(rawValue: "Genre")
		static let Year = NSUserInterfaceItemIdentifier(rawValue: "Year")
		static let Waveform = NSUserInterfaceItemIdentifier(rawValue: "Waveform")
		static let Duration = NSUserInterfaceItemIdentifier(rawValue: "Duration")
	}

	enum CellIdentifiers {
		static let ImageCell = NSUserInterfaceItemIdentifier(rawValue: "ImageCell")
		static let TrackCell = NSUserInterfaceItemIdentifier(rawValue: "TrackCell")
		static let TempoCell = NSUserInterfaceItemIdentifier(rawValue: "TempoCell")
		static let KeyCell = NSUserInterfaceItemIdentifier(rawValue: "KeyCell")
		static let AlbumCell = NSUserInterfaceItemIdentifier(rawValue: "AlbumCell")
		static let ArtistsCell = NSUserInterfaceItemIdentifier(rawValue: "ArtistsCell")
		static let GenreCell = NSUserInterfaceItemIdentifier(rawValue: "GenreCell")
		static let YearCell = NSUserInterfaceItemIdentifier(rawValue: "YearCell")
		static let WaveformCell = NSUserInterfaceItemIdentifier(rawValue: "WaveformCell")
		static let DurationCell = NSUserInterfaceItemIdentifier(rawValue: "DurationCell")
	}

	func initColumns() {
		tableView.tableColumns.forEach(tableView.removeTableColumn)
		
		func addColumn(_ identifier: NSUserInterfaceItemIdentifier, title: String, fun: (NSTableColumn) -> Void) {
			let column = NSTableColumn(identifier: identifier)
			column.title = title
			column.resizingMask = .userResizingMask
			fun(column)
			tableView.addTableColumn(column)
		}
		
		addColumn(ColumnIdentifiers.Image, title: "⸬") {
			$0.widthRange = tableView.rowHeight...tableView.rowHeight
			$0.headerCell.alignment = .center
		}
		
		addColumn(ColumnIdentifiers.Waveform, title: "􀙫") {
			$0.widthRange = 42...CGFloat.infinity
			$0.width = 50
			$0.headerCell.alignment = .center
		}

		addColumn(ColumnIdentifiers.Title, title: "Title") {
			$0.widthRange = 150...CGFloat.infinity
			$0.resizingMask = [.autoresizingMask, .userResizingMask]
		}
		
		addColumn(ColumnIdentifiers.Artists, title: "Artists") {
			$0.widthRange = 60...CGFloat.infinity
			$0.headerCell.alignment = .center
			$0.isHidden = true
		}
		
		addColumn(ColumnIdentifiers.Album, title: "Album") {
			$0.widthRange = 60...CGFloat.infinity
			$0.headerCell.alignment = .center
			$0.isHidden = true
		}
		
		addColumn(ColumnIdentifiers.Genre, title: "Genre") {
			$0.widthRange = 60...CGFloat.infinity
			$0.headerCell.alignment = .center
			$0.isHidden = true
		}
		
		addColumn(ColumnIdentifiers.Year, title: "Year") {
			$0.widthRange = 42...42
			$0.headerCell.alignment = .center
			$0.isHidden = true
		}

		addColumn(ColumnIdentifiers.Tempo, title: "♩=") {
			$0.widthRange = 52...52
			$0.headerCell.alignment = .center
		}

		addColumn(ColumnIdentifiers.Key, title: "♫") {
			$0.widthRange = 42...42
			$0.headerCell.alignment = .center
		}

		addColumn(ColumnIdentifiers.Duration, title: "􀐫") {
			$0.widthRange = 60...60
			$0.headerCell.alignment = .center
		}

		tableViewHiddenExtension = .init(tableView: tableView, titles: [
			ColumnIdentifiers.Image: "Artwork (⸬)",
			ColumnIdentifiers.Tempo: "Beats per Minute (♩=)",
			ColumnIdentifiers.Key: "Initial Key (♫)",
			ColumnIdentifiers.Waveform: "Waveform (􀙫)",
			ColumnIdentifiers.Duration: "Duration (􀐫)",
		], affix: [ColumnIdentifiers.Title])
		tableViewHiddenExtension.attach()
		
		tableView.autosaveName = "tableViewTracks"
		tableView.autosaveTableColumns = true
		tableViewSynchronizer = .init(tableView: tableView)
		tableViewSynchronizer.attach()
	}
	
	func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
		let track = self.tracks[row]
		
		func makeView(for id: NSUserInterfaceItemIdentifier, fun: (AnyNSHostingView) -> Void) -> NSView? {
			if let view = tableView.makeView(withIdentifier: id, owner: nil) as? AnyNSHostingView {
				fun(view)
				return view
			}
			appLogger.error("Failed to create known track view: \(id)")
			return nil
		}
		
		switch tableColumn?.identifier {
		case ColumnIdentifiers.Title:
			return makeView(for: CellIdentifiers.TrackCell) {
				$0.rootView = AnyView(TrackCellView(track: track))
			}
		case ColumnIdentifiers.Image:
			return makeView(for: CellIdentifiers.ImageCell) {
				$0.rootView = AnyView(PlayTrackImageView(track: track, context: .playlist(playlist.backend, tracks: tracks.map(\.backend), track: track.backend))
										.environment(\.library, library)
							.environment(\.player, library.player)
						)
			}
		case ColumnIdentifiers.Waveform:
			return makeView(for: CellIdentifiers.WaveformCell) {
				$0.rootView = AnyView(PlayPositionView(player: player, track: track.backend, isSecondary: true))
			}
		case ColumnIdentifiers.Tempo:
			return makeView(for: CellIdentifiers.TempoCell) {
				$0.rootView = AnyView(TrackTempoView(track: track))
			}
		case ColumnIdentifiers.Key:
			return makeView(for: CellIdentifiers.KeyCell) {
				$0.rootView = AnyView(TrackKeyView(track: track))
			}
		case ColumnIdentifiers.Artists:
			return makeView(for: CellIdentifiers.ArtistsCell) {
				$0.rootView = AnyView(TrackArtistsView(track: track))
			}
		case ColumnIdentifiers.Album:
			return makeView(for: CellIdentifiers.AlbumCell) {
				$0.rootView = AnyView(TrackAlbumView(track: track, withIcon: false))
			}
		case ColumnIdentifiers.Genre:
			return makeView(for: CellIdentifiers.GenreCell) {
				$0.rootView = AnyView(TrackGenreView(track: track))
			}
		case ColumnIdentifiers.Duration:
			return makeView(for: CellIdentifiers.DurationCell) {
				$0.rootView = AnyView(TrackDurationView(track: track))
			}
		default:
			appLogger.error("Unrecognized track view: \(String(describing: tableColumn))")
			return nil
		}
	}
	
	func tableView(_ tableView: NSTableView, shouldTypeSelectFor event: NSEvent, withCurrentSearch searchString: String?) -> Bool {
		// Deny "space" searches as they are more likely pause/play
//		!Keycodes.space.matches(event: event)
		false  // needs typeSelectString to be properly implemented, which requires caching of remote values
	}
}

extension TracksViewController: NSTableViewDataSource {
	func numberOfRows(in tableView: NSTableView) -> Int {
		tracks.count
	}
}
