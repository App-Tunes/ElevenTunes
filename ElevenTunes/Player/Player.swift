//
//  Player.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 19.12.20.
//

import Foundation
import Combine

class Player {
    @Published var playing: Track?
    @Published var state: PlayerState = .init(isPlaying: false, currentTime: nil)

    let singlePlayer = SinglePlayer()

    private var currentEmitterTask: AnyCancellable?
    private var nextEmitter: AnyPublisher<AnyAudioEmitter, Error>?
    
    private var nextObserver: AnyCancellable?
    private var stateObserver: AnyCancellable?

    init() {
        stateObserver = singlePlayer.$state.assign(to: \.state, on: self)
        singlePlayer.delegate = self
    }
    
    var history: PlayHistory = PlayHistory() {
        didSet {
            nextObserver?.cancel()
            preload(history.next)
            nextObserver = history.$next.sink { [unowned self] next in
                print("Preload \(next)")
                self.preload(next)
            }
        }
    }
        
    private func preload(_ track: Track?) {
        guard let track = track, let backend = track.backend else {
            nextEmitter = nil
            return
        }

        nextEmitter = backend.audio()
    }
    
    func toggle() {
        singlePlayer.toggle()
    }
    
    func play(_ track: Track?) {
        history = PlayHistory(track != nil ? [track!] : [])
        next()
    }
    
    func play(_ history: PlayHistory) {
        self.history = history
        next()
    }
    
    @discardableResult
    func next() -> Bool {
        // if that's still loading... don't need it anymore
        currentEmitterTask?.cancel()
        singlePlayer.stop()
                
        guard let nextEmitter = self.nextEmitter else {
            // No track was scheduled. Nothing to play
            self.currentEmitterTask = nil
            // It might have been nothing because the file was a mock file
            playing = history.pop()
            return false
        }
        
        currentEmitterTask = nextEmitter
        .receive(on: RunLoop.main)
        .sink(receiveCompletion: { completion in
            switch completion {
            case .failure(let error):
                appLogger.error("Play Failure: \(error)")
                self.singlePlayer.play(nil)
            default:
                break
            }
        }) { emitter in
            self.singlePlayer.play(emitter)
        }
        // Update our playing state
        // Auto-triggers next track load
        playing = history.pop()

        // TODO Play
        return true
    }
}

extension Player: SinglePlayerDelegate {
    func playerDidStop(_ player: SinglePlayer) {
        next()
    }
}
