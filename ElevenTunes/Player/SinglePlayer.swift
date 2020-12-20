//
//  SoundPlayer.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 19.12.20.
//

import Foundation

protocol SinglePlayerDelegate: AnyObject {
    func playerDidStop(_ player: SinglePlayer)
}

// Player capable of playing one file at a time
class SinglePlayer {
    // Unfortunately, K/V observation on this doesn't seem to work :(
    @Published private(set) var playing: AnyAudioEmitter? {
        willSet {
            playing?.delegate = nil
            playing?.stop()
        }
        didSet { playing?.delegate = self }
    }
    
    @Published private(set) var state = PlayerState(isPlaying: false, currentTime: nil)
    
    weak var delegate: SinglePlayerDelegate?
    
    func _updateState() {
        state = .init(isPlaying: playing?.isPlaying ?? false, currentTime: playing?.currentTime ?? nil)
    }
    
    func play(_ emitter: AnyAudioEmitter?) {
        self.playing = emitter // Will toggle stop()
        
        guard let emitter = emitter else {
            return
        }
        
        emitter.delegate = self
        emitter.start()
    }
    
    func stop() {
        playing = nil // Will toggle stop()
    }
    
    func toggle() {
        guard let playing = playing else {
            return  // TODO Nothing to toggle, trigger playback!
        }

        if playing.isPlaying {
            playing.stop()
        }
        else {
            playing.start()
        }
    }
    
    deinit {
        stop()
    }
}

extension SinglePlayer: AudioEmitterDelegate {
    func emitterDidStop(_ emitter: AnyAudioEmitter) {
        playing = nil
        _updateState()
        
        delegate?.playerDidStop(self)
    }
    
    func emitterUpdatedState(_ emitter: AnyAudioEmitter) {
        _updateState()
    }
}
