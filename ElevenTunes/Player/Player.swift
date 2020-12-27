//
//  Player.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 19.12.20.
//

import Foundation
import Combine

class Player {
    @Published var previous: Track? {
        didSet {
            // Re-use last played if possible
            previousEmitter =
                oldValue?.id == previous?.id ? previousEmitter
                : previous?.id == current?.id ? currentEmitter
                : previous?.emitter()
        }
    }
    
    @Published var current: Track? {
        didSet {
            // If possible, use prepared caches
            currentEmitter =
                oldValue?.id == current?.id ? currentEmitter
                : current?.id == next?.id ? nextEmitter
                : current?.id == previous?.id ? previousEmitter
                : current?.emitter()
        }
    }
    @Published var next: Track? {
        didSet {
            // Re-use last played if possible
            nextEmitter =
                oldValue?.id == next?.id ? nextEmitter
                : next?.id == current?.id ? currentEmitter
                : next?.emitter()
        }
    }

    @Published var isAlmostNext: Bool = false

    @Published var state: PlayerState = .init(isPlaying: false, currentTime: nil)

    let singlePlayer = SinglePlayer()

    private var currentEmitterTask: AnyCancellable?
    private var currentEmitter: AnyPublisher<AnyAudioEmitter, Error>? {
        didSet { load() }
    }
    private var previousEmitter: AnyPublisher<AnyAudioEmitter, Error>?
    private var nextEmitter: AnyPublisher<AnyAudioEmitter, Error>?

    private var historyObservers = Set<AnyCancellable>()

    init() {
        singlePlayer.$state.assign(to: &$state)
        singlePlayer.$isAlmostDone.assign(to: &$isAlmostNext)
        singlePlayer.delegate = self
    }
    
    var history: PlayHistory = PlayHistory() {
        didSet {
            historyObservers = []
            
            // Assign current first, in the low offchance we can re-use a cache
            history.$current.assignWeak(to: \Player.current, on: self)
                .store(in: &historyObservers)
            history.$next.assignWeak(to: \Player.next, on: self)
                .store(in: &historyObservers)
            history.$previous.assignWeak(to: \Player.previous, on: self)
                .store(in: &historyObservers)
        }
    }
            
    func toggle() {
        singlePlayer.toggle()
    }
    
    func play(_ track: Track?) {
        history = PlayHistory(track != nil ? [track!] : [])
        forwards()
    }
    
    func play(_ history: PlayHistory) {
        self.history = history
        forwards()
    }
    
    private func load() {
        let player = singlePlayer
        player.stop()

        currentEmitterTask = currentEmitter?
            .onMain()
            .sink(receiveCompletion: { completion in
                switch completion {
                case .failure(let error):
                    appLogger.error("Play Failure: \(error)")
                    player.play(nil)
                default:
                    break
                }
            }) { emitter in
                // Start from beginning
                try? emitter.move(to: 0)
                player.play(emitter)
            }
        
        if currentEmitter == nil {
            player.play(nil)
        }
    }
    
    @discardableResult
    func forwards() -> Bool {
        currentEmitterTask?.cancel()
        history.forwards()
        return true
    }
    
    @discardableResult
    func backwards() -> Bool {
        history.backwards()
        return true
    }
}

extension Player: SinglePlayerDelegate {
    func playerDidStop(_ player: SinglePlayer) {
        forwards()
    }
}
