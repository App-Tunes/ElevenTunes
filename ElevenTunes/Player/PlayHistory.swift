//
//  PlayHistory.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 19.12.20.
//

import Foundation
import Combine

enum PlayHistoryContext {
    case playlist(_ playlist: AnyPlaylist, tracks: [AnyTrack], track: AnyTrack)
	
	var fromStart: PlayHistoryContext {
		switch self {
		case .playlist(let playlist, let tracks, _):
			return .playlist(playlist, tracks: tracks, track: tracks[0])
		}
	}
}

class PlayHistory {
	var context: PlayHistoryContext?
	
    @Published private(set) var queue: [AnyTrack]
    @Published private(set) var history: [AnyTrack] = []

    // previous = history.last, next = queue.first
    @Published private(set) var previous: AnyTrack?
    @Published private(set) var current: AnyTrack?
    @Published private(set) var next: AnyTrack?
    
    init(_ queue: [AnyTrack] = [], history: [AnyTrack] = []) {
        self.queue = queue
        self.history = history
        
        $queue.map(\.first).assign(to: &$next)
        $history.map(\.last).assign(to: &$previous)
    }
    
    convenience init(context: PlayHistoryContext) {
        switch context {
        case .playlist(_, let tracks, let track):
			let index = tracks.firstIndex { $0.id == track.id } ?? tracks.count
            self.init(Array(tracks[index...]), history: Array(tracks[..<index]))
        }
		self.context = context
    }
	        
    @discardableResult
    func forwards() -> AnyTrack? {
        // Move forwards in replacements so that no value is missing at any point
        if let current = current { history.append(current) }
        current = queue.first
        _ = queue.popFirst()
        
        return current
    }
    
    @discardableResult
    func backwards() -> AnyTrack? {
        // Move backwards in replacements so that no value is missing at any point
        if let current = current { queue.prepend(current) }
        current = history.last
        _ = history.popLast()
        
        return current
    }
}
