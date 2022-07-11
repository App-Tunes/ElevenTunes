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

    @Published private(set) var previous: AnyTrack?
    @Published private(set) var current: AnyTrack?
    @Published private(set) var next: AnyTrack?
	
	let context: PlayContext
	let singlePlayer = SinglePlayer()

	/// States in this player convey user intention, not actual state. e.g. it may be "playing"
	/// while no music is being released, since the track is yet loading. For technical state,
	/// view singlePlayer states.
	@Published private(set) var isPlaying: Bool = false
	@Published private(set) var isAlmostNext: Bool = false
	private var playingID: String?

    private var currentEmitterTask: AnyCancellable?
    private var currentEmitter: AnyPublisher<AudioTrack, Error>? {
        didSet { load() }
    }
    private var previousEmitter: AnyPublisher<AudioTrack, Error>?
    private var nextEmitter: AnyPublisher<AudioTrack, Error>?

	private var cancellables = Set<AnyCancellable>()
	private var historyObservers = Set<AnyCancellable>()

    init(context: PlayContext) {
        self.context = context
		singlePlayer.delegate = self
        singlePlayer.$isAlmostDone.assign(to: &$isAlmostNext)
    }
	
	func prepare(_ track: AnyTrack?) -> AnyPublisher<AudioTrack, Error>? {
		guard let track = track else {
			return nil
		}
		
		return context.deviceStream.eraseError()
			.tryMap { try track.audioTrack(forDevice: $0) }
			.flatMap { $0 }
			.eraseToAnyPublisher()
	}
    
    var history: PlayHistory = PlayHistory() {
        didSet {
            historyObservers = []
            
			historyObservers.insert(
				Publishers.Concatenate(prefix: Just(history), suffix: history.changePublisher)
					.sink { [weak self] _ in
						self?.updateFromHistory()
					}
			)
        }
    }
	
	private func updateFromHistory() {
		// Re-use emitters if possible
		var emitters: [String: AnyPublisher<AudioTrack, Error>] = .init()
		if let previous = previous { emitters[previous.id] = previousEmitter }
		if let current = current { emitters[current.id] = currentEmitter }
		if let next = next { emitters[next.id] = nextEmitter }

		previous = history.previous
		current = history.current
		next = history.next

		previousEmitter = previous.flatMap { emitters[$0.id] } ?? prepare(previous)
		currentEmitter = current.flatMap { emitters[$0.id] } ?? prepare(current)
		nextEmitter = next.flatMap { emitters[$0.id] } ?? prepare(next)
	}
            
    func toggle() {
		if history.current == nil, let context = history.context {
			play(context.fromStart.makeHistory())
			return
		}
		
        singlePlayer.toggle()
		isPlaying = singlePlayer.state.isPlaying
    }
    
	func play(_ track: AnyTrack?, at time: TimeInterval? = nil) {
		history = PlayHistory(current: track)
		// TODO time is ignored; how to propagate? lol
    }
    
    func play(_ history: PlayHistory) {
        self.history = history
    }
    
    private func load() {
        singlePlayer.stop()

		guard let currentEmitter = currentEmitter else {
			singlePlayer.switchTo(nil)
			isPlaying = false
			playingID = nil
			return
		}

		let trackID = current?.id
		isPlaying = true
        currentEmitterTask = currentEmitter
            .onMain()
			.sink(receiveResult: { [weak self] in
				guard let self = self else { return }
				
				switch $0 {
				case .failure(let error):
					// TODO Think about graceful handling
					self.singlePlayer.switchTo(nil)
					self.isPlaying = false
					NSAlert.warning(title: "Play Failure", text: error.localizedDescription)
				case .success(let audio):
					if self.playingID == trackID {
						// Start from where we were, but in new audio
						try? audio.move(to: self.singlePlayer.playing?.currentTime ?? 0)
						self.singlePlayer.switchTo(audio, andPlay: self.isPlaying)
					}
					else {
						// Start from beginning
						try? audio.move(to: 0)
						self.singlePlayer.switchTo(audio, andPlay: self.isPlaying)
					}
				}
				
				// TODO isPlaying should be noted by this Player. singlePlayer only
				// knows for the current track.
				self.playingID = trackID
			})
    }
    
    @discardableResult
    func forwards() -> Bool {
		history.forwards()

		currentEmitterTask?.cancel()
		if history.current == nil && repeatEnabled, let context = history.context {
			play(context.fromStart.makeHistory())
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
