//
//  Player.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 19.12.20.
//

import Foundation
import Combine

class Player {
    @Published var previous: Track?
    
    @Published var current: Track? {
        didSet {
            // Did we move forwards?
            currentEmitter = current == next
                ? nextEmitter
                : current?.backend?.audio()
        }
    }
    @Published var next: Track? {
        didSet {
            // Did we move backwards?
            nextEmitter = next == current
                ? currentEmitter
                : next?.backend?.audio()
        }
    }

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
        singlePlayer.delegate = self
    }
    
    var history: PlayHistory = PlayHistory() {
        didSet {
            historyObservers = []
            
            history.$current.assignWeak(to: \Player.current, on: self)
                .store(in: &historyObservers)
            history.$previous.assignWeak(to: \Player.previous, on: self)
                .store(in: &historyObservers)
            history.$next.assignWeak(to: \Player.next, on: self)
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
            .receive(on: RunLoop.main)
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
