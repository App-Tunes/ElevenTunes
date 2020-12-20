//
//  PlayHistory.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 19.12.20.
//

import Foundation
import Combine

class PlayHistory {
    @Published private(set) var queue: [Track]
    @Published private(set) var next: Track?
    private(set) var history: [Track] = []
        
    private var nextObserver: AnyCancellable?
    
    init(_ queue: [Track] = [], history: [Track] = []) {
        self.queue = queue
        self.history = history
        
        nextObserver = $queue.sink { [unowned self] newValue in
            self.next = newValue.first
        }
    }
    
    convenience init(_ playlist: Playlist, at track: Track) {
        let tracks = playlist.tracks
        let trackIdx = tracks.firstIndex(of: track)
        if trackIdx == nil {
            appLogger.error("Failed to find \(track) in \(playlist)")
        }
        let idx = trackIdx ?? 0
        
        self.init(Array(tracks[idx...]), history: Array(tracks[..<idx]))
    }
    
    @discardableResult
    func pop() -> Track? {
        guard let track = queue.popFirst() else {
            return nil
        }
        
        history.append(track)
        return track
    }
}
