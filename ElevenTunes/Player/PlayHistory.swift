//
//  PlayHistory.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 19.12.20.
//

import Foundation
import Combine

class History<Item> {
	var context: PlayHistoryContext?
	
    @Published private(set) var queue: [Item]
    @Published private(set) var history: [Item] = []

    // previous = history.last, next = queue.first
    @Published private(set) var previous: Item?
    @Published private(set) var current: Item?
    @Published private(set) var next: Item?
    
    init(_ queue: [Item] = [], history: [Item] = []) {
        self.queue = queue
        self.history = history
        
        $queue.map(\.first).assign(to: &$next)
        $history.map(\.last).assign(to: &$previous)
    }
    	        
    @discardableResult
    func forwards() -> Item? {
        // Move forwards in replacements so that no value is missing at any point
        if let current = current { history.append(current) }
        current = queue.first
        _ = queue.popFirst()
        
        return current
    }
    
    @discardableResult
    func backwards() -> Item? {
        // Move backwards in replacements so that no value is missing at any point
        if let current = current { queue.prepend(current) }
        current = history.last
        _ = history.popLast()
        
        return current
    }
}

typealias PlayHistory = History<AnyTrack>

enum PlayHistoryContext {
	case playlist(_ playlist: AnyPlaylist, tracks: [AnyTrack], track: AnyTrack)
	
	var fromStart: PlayHistoryContext {
		switch self {
		case .playlist(let playlist, let tracks, _):
			return .playlist(playlist, tracks: tracks, track: tracks[0])
		}
	}
}

extension PlayHistory {
	convenience init(context: PlayHistoryContext) {
		switch context {
		case .playlist(_, let tracks, let track):
			let index = tracks.firstIndex { $0.id == track.id } ?? tracks.count
			self.init(Array(tracks[index...]), history: Array(tracks[..<index]))
		}
		self.context = context
	}
}
