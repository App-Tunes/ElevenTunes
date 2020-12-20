//
//  AVFoundationAudioEmitter.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 20.12.20.
//

import Foundation
import AVFoundation

class AVFoundationAudioEmitter: NSObject, AnyAudioEmitter {
    let audio: AVAudioPlayer
    
    weak var delegate: AudioEmitterDelegate? = nil

    init(_ audio: AVAudioPlayer) {
        self.audio = audio
        super.init()
        audio.delegate = self
    }
    
    var currentTime: TimeInterval? { audio.currentTime }
    var isPlaying: Bool { audio.isPlaying }

    var duration: TimeInterval? { audio.duration }
    
    func move(to time: TimeInterval) {
        audio.currentTime = time
        delegate?.emitterUpdatedState(self)
    }
    
    func start() {
        audio.play()
        delegate?.emitterUpdatedState(self)
    }
    
    func stop() {
        audio.stop()
        delegate?.emitterUpdatedState(self)
    }
}

extension AVFoundationAudioEmitter : AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        delegate?.emitterDidStop(self)
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        // TODO
        appLogger.error("Audio Decode Error: \(String(describing: error))")
    }
}
