//
//  Player.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 19.12.20.
//

import Foundation
import Combine

class Player {
	@Published var repeatEnabled: Bool = false

    @Published var previous: AnyTrack? {
        didSet {
            // Re-use last played if possible
            previousEmitter =
                oldValue?.id == previous?.id ? previousEmitter
                : previous?.id == current?.id ? currentEmitter
                : prepare(previous)
        }
    }
    
    @Published var current: AnyTrack? {
        didSet {
            // If possible, use prepared caches
            currentEmitter =
                oldValue?.id == current?.id ? currentEmitter
                : current?.id == next?.id ? nextEmitter
                : current?.id == previous?.id ? previousEmitter
                : prepare(current)
        }
    }
    @Published var next: AnyTrack? {
        didSet {
            // Re-use last played if possible
            nextEmitter =
                oldValue?.id == next?.id ? nextEmitter
                : next?.id == current?.id ? currentEmitter
				: prepare(next)
        }
    }

    @Published var isAlmostNext: Bool = false

    @Published var state: PlayerState = .init(isPlaying: false, currentTime: nil)
    let context: PlayContext
    
    let singlePlayer = SinglePlayer()

    private var currentEmitterTask: AnyCancellable?
    private var currentEmitter: AnyPublisher<AudioTrack, Error>? {
        didSet { load() }
    }
    private var previousEmitter: AnyPublisher<AudioTrack, Error>?
    private var nextEmitter: AnyPublisher<AudioTrack, Error>?

    private var historyObservers = Set<AnyCancellable>()

    init(context: PlayContext) {
        self.context = context
        singlePlayer.$state.assign(to: &$state)
        singlePlayer.$isAlmostDone.assign(to: &$isAlmostNext)
        singlePlayer.delegate = self
    }
	
	func prepare(_ track: AnyTrack?) -> AnyPublisher<AudioTrack, Error>? {
		guard let track = track else {
			return nil
		}
		
		return context.deviceStream.eraseError()
			.tryFlatMap { try track.audioTrack(forDevice: $0) }
			.eraseToAnyPublisher()
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
		if history.current == nil, let context = history.context {
			play(PlayHistory(context: context.fromStart))
			return
		}
		
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
        singlePlayer.stop()

		if currentEmitter == nil {
			singlePlayer.play(nil)
		}

        currentEmitterTask = currentEmitter?
            .onMain()
			.sink(receiveResult: { [weak self] in
				guard let self = self else { return }
				
				switch $0 {
				case .failure(let error):
					NSAlert.warning(title: "Play Failure", text: error.localizedDescription)
					// TODO Think about graceful handling
					self.singlePlayer.play(nil)
				case .success(let audio):
					// Start from beginning
					try? audio.move(to: 0)
					self.singlePlayer.play(audio)
				}
			})
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
