//
//  AnySinglePlayer.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 20.12.20.
//

import Foundation

struct PlayerState {
    var isPlaying: Bool
    var currentTime: TimeInterval?
}

public protocol AudioEmitterDelegate: AnyObject {
    func emitterDidStop(_ emitter: AnyAudioEmitter)
    func emitterUpdatedState(_ emitter: AnyAudioEmitter)
}

class InvalidTimeError: Error {
    
}

public protocol AnyAudioEmitter: AnyObject {
    var delegate: AudioEmitterDelegate? { get set }
    
    var currentTime: TimeInterval? { get }
    var isPlaying: Bool { get }
    
    var duration: TimeInterval? { get }

    func move(to time: TimeInterval) throws
    func start()
    func stop()
}
