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
    private(set) var tracksPrevious: [Track] = []
        
    private var nextObserver: AnyCancellable?
    
    init(_ tracks: [Track] = []) {
        queue = tracks
        nextObserver = $queue.sink { [unowned self] newValue in
            let newNext = newValue.first
            if newNext != self.next {
                self.next = newNext
            }
        }
    }
    
    @discardableResult
    func pop() -> Track? {
        guard let track = queue.popLast() else {
            return nil
        }
        
        tracksPrevious.append(track)
        return track
    }
}
