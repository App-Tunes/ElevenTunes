//
//  PlayHistory.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 19.12.20.
//

import TunesLogic

class PlayHistory: History<AnyTrack> {
	typealias Item = AnyTrack
	let context: PlayHistoryContext?
	
	public override init(history: [Item] = [], current: Item? = nil, queue: [Item] = []) {
		self.context = nil
		super.init(history: history, current: current, queue: queue)
	}
	
	public init(context: PlayHistoryContext) {
		self.context = context
		
		switch context {
		case .playlist(_, let tracks, let track):
			if let index = tracks.firstIndex(where: { $0.id == track.id }) {
				super.init(
					history: Array(tracks[..<index]),
					current: track,
					queue: Array(tracks[(index + 1)...])
				)
			}
			else {
				// Track can't be found in playlist
				super.init(
					history: tracks,
					current: track,
					queue: []
				)
			}
		}
	}
}

enum PlayHistoryContext {
	case playlist(_ playlist: AnyPlaylist, tracks: [AnyTrack], track: AnyTrack)
	
	var fromStart: PlayHistoryContext {
		switch self {
		case .playlist(let playlist, let tracks, _):
			return .playlist(playlist, tracks: tracks, track: tracks[0])
		}
	}
	
	func makeHistory() -> PlayHistory {
		.init(context: self)
	}
}
