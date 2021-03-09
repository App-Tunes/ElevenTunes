//
//  Player.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 19.12.20.
//

import Foundation
import Combine

public struct PlayContext {
    var spotify: Spotify
}

class Player {
	@Published var repeatEnabled: Bool = false

    @Published var previous: AnyTrack? {
        didSet {
            // Re-use last played if possible
            previousEmitter =
                oldValue?.id == previous?.id ? previousEmitter
                : previous?.id == current?.id ? currentEmitter
                : previous?.emitter(context: context)
        }
    }
    
    @Published var current: AnyTrack? {
        didSet {
            // If possible, use prepared caches
            currentEmitter =
                oldValue?.id == current?.id ? currentEmitter
                : current?.id == next?.id ? nextEmitter
                : current?.id == previous?.id ? previousEmitter
                : current?.emitter(context: context)
        }
    }
    @Published var next: AnyTrack? {
        didSet {
            // Re-use last played if possible
            nextEmitter =
                oldValue?.id == next?.id ? nextEmitter
                : next?.id == current?.id ? currentEmitter
                : next?.emitter(context: context)
        }
    }

    @Published var isAlmostNext: Bool = false

    @Published var state: PlayerState = .init(isPlaying: false, currentTime: nil)
    var context: PlayContext
    
    let singlePlayer = SinglePlayer()

    private var currentEmitterTask: AnyCancellable?
    private var currentEmitter: AnyPublisher<AnyAudioEmitter, Error>? {
        didSet { load() }
    }
    private var previousEmitter: AnyPublisher<AnyAudioEmitter, Error>?
    private var nextEmitter: AnyPublisher<AnyAudioEmitter, Error>?

    private var historyObservers = Set<AnyCancellable>()

    init(context: PlayContext) {
        self.context = context
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
    
    func play(_ track: AnyTrack?) {
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
		if history.current == nil && repeatEnabled, let context = history.context {
			play(PlayHistory(context: context.fromStart))
		}
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
