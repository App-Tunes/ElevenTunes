//
//  TracksViewController.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 07.03.21.
//

import Cocoa
import Combine
import TunesUI

class TracksViewController: NSViewController {
	@IBOutlet weak var tableView: NSTableViewContextSensitiveMenu! = nil
	var tableViewHiddenExtension: NSTableView.ColumnHiddenExtension!
	var tableViewSynchronizer: NSTableView.ActiveSynchronizer!

	var library: Library
	var player: Player {
		didSet {
			updatePlayerObserver()
		}
	}

	var playlist: Playlist {
		didSet {
			updatePlaylistObserver()
		}
	}
	
	private(set) var tracks: [Track] = []
	private(set) var tracksState: TrackAttributes.State = .missing
	
	var playerObserver: AnyCancellable?
	var playlistObserver: AnyCancellable?

	var cancellables = Set<AnyCancellable>()
	
	init(_ playlist: Playlist, library: Library, player: Player) {
		self.playlist = playlist
		self.library = library
		self.player = player
		super.init(nibName: nil, bundle: .main)
		updatePlaylistObserver()
		updatePlayerObserver()
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		initColumns()

		tableView.returnAction = #selector(didPressReturn(_:))

		tableView.registerForDraggedTypes(TrackInterpreter.standard.types.map { .init(rawValue: $0.identifier ) })
		tableView.registerForDraggedTypes([.init(TracksExportManager.tracksIdentifier)])

		tableView.backgroundColor = NSColor.clear
		tableView.sizeToFit()
	}
	
	private func updateTracks(_ tracks: [Track], animate: Bool) {
		let oldValue = self.tracks
		
		self.tracks = tracks
		if animate {
			tableView?.animateDifference(from: oldValue, to: self.tracks)
		}
		else {
			tableView?.reloadData()
		}
	}
	
	private func updatePlaylistObserver() {
		// No animation when changing playlists
		self.updateTracks([], animate: false)
		self.tracksState = .missing

		playlistObserver = playlist.backend.attribute(PlaylistAttribute.tracks).sink { [weak self] snapshot in
			guard let self = self else { return }
			
			// Don't update for unknown states, they will resolve soon enough
			guard snapshot.state.isKnown else {
				self.tracksState = snapshot.state
				return
			}

			// Animate only between known values
			self.updateTracks(snapshot.value?.map { Track($0) } ?? [], animate: self.tracksState.isKnown && snapshot.state.isKnown)
			self.tracksState = snapshot.state
		}
	}
	
	private func updatePlayerObserver() {
		playerObserver = PlayerTrackState.observing(player)
			.sink{ [weak self] state in
				guard let self = self, let tableView = self.tableView else { return }
				
				guard let column = tableView.column(withIdentifier: ColumnIdentifiers.Waveform).positiveOrNil else {
					return
				}
				
				for row in tableView.rows(in: tableView.visibleRect).asRange {
					guard let view = tableView.view(atColumn: column, row: row, makeIfNecessary: false) as? PlayPositionViewCocoa else {
						continue
					}
					
					let viewState = state.viewedAs(view.track)
					view.positionControl.timer.fps = viewState.state.isPlaying ? PlayPositionViewCocoa.activeFPS : nil
				}
			}
	}
}
