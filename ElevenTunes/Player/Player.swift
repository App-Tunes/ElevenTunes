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

    let soundPlayer = SinglePlayer()

    private var currentFile: AnyCancellable?
    private var nextFile: AnyPublisher<AnyAudioEmitter, Error>?
    
    private var nextObserver: AnyCancellable?
    private var stateObserver: AnyCancellable?

    init() {
        stateObserver = soundPlayer.$state.assign(to: \.state, on: self)
    }
    
    var history: PlayHistory = PlayHistory() {
        didSet {
            nextObserver?.cancel()
            preload(history.next)
            nextObserver = history.$next.sink { [unowned self] next in
                self.preload(next)
            }
        }
    }
        
    private func preload(_ track: Track?) {
        guard let track = track, let backend = track.backend else {
            nextFile = nil
            return
        }

        nextFile = backend.audio()
    }
    
    func toggle() {
        soundPlayer.toggle()
    }
    
    func play(_ track: Track?) {
        history = PlayHistory(track != nil ? [track!] : [])
        next()
    }
    
    @discardableResult
    func next() -> Bool {
        // if that's still loading... don't need it anymore
        currentFile?.cancel()
        soundPlayer.stop()
                
        guard let nextFile = self.nextFile else {
            // No track was scheduled. Nothing to play
            self.currentFile = nil
            // It might have been nothing because the file was a mock file
            playing = history.pop()
            return false
        }
        
        currentFile = nextFile
        .receive(on: RunLoop.main)
        .sink(receiveCompletion: { completion in
            switch completion {
            case .failure(let error):
                appLogger.error("Play Failure: \(error)")
                self.soundPlayer.play(nil)
            default:
                break
            }
        }) { player in
            self.soundPlayer.play(player)
        }
        // Update our playing state
        // Auto-triggers next track load
        playing = history.pop()

        // TODO Play
        return true
    }
}
