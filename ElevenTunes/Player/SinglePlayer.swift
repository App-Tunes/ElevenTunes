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
    static let timeInAnAlmost: TimeInterval = 5
    
    // Unfortunately, K/V observation on this doesn't seem to work :(
    @Published private(set) var playing: AnyAudioEmitter? {
        willSet {
            playing?.delegate = nil
            playing?.stop()
        }
        didSet { playing?.delegate = self }
    }
    
    @Published private(set) var state = PlayerState(isPlaying: false, currentTime: nil)
    @Published private(set) var isAlmostDone = false

    private var almostDoneTimer: Timer?
    
    weak var delegate: SinglePlayerDelegate?
    
    func _updateState() {
        state = .init(isPlaying: playing?.isPlaying ?? false, currentTime: playing?.currentTime ?? nil)
        
        almostDoneTimer?.invalidate()
        if let duration = playing?.duration, let currentTime = playing?.currentTime {
            let timeLeft = duration - currentTime
            
            if timeLeft > SinglePlayer.timeInAnAlmost {
                isAlmostDone = false
                almostDoneTimer = Timer.scheduledTimer(withTimeInterval: duration - currentTime, repeats: false, block: { [unowned self] _ in
                    self.isAlmostDone = true
                })
            }
            else {
                isAlmostDone = true
            }
        }
        else {
            isAlmostDone = false
        }
    }
    
    func play(_ emitter: AnyAudioEmitter?) {
        self.playing = emitter // Will toggle stop() on previous
        
        guard let emitter = emitter else {
            _updateState()
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
        DispatchQueue.main.async {
            self.playing = nil
            self._updateState()
            
            self.delegate?.playerDidStop(self)
        }
    }
    
    func emitterUpdatedState(_ emitter: AnyAudioEmitter) {
        DispatchQueue.main.async {
            self._updateState()
        }
    }
}
