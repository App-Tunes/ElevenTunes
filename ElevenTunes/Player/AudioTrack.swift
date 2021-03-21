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

public protocol AudioTrackDelegate: AnyObject {
    func emitterDidStop(_ emitter: AudioTrack)
    func emitterUpdatedState(_ emitter: AudioTrack)
}

class InvalidTimeError: Error { }

public protocol AudioTrack: AnyObject {
    var delegate: AudioTrackDelegate? { get set }
    
    var currentTime: TimeInterval? { get }
    var isPlaying: Bool { get }
    
    var duration: TimeInterval? { get }
	
	var volume: Double { get set }

    func move(to time: TimeInterval) throws
    func start()
    func stop()
}
