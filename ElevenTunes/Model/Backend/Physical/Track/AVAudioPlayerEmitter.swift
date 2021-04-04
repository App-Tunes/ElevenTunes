//
//  AVFoundationAudioEmitter.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 20.12.20.
//

import Foundation
import AVFoundation

class AVAudioPlayerEmitter: NSObject, AudioTrack {
	let device: AVSingleAudioDevice
	let duration: TimeInterval?
	
    weak var delegate: AudioTrackDelegate? = nil

	init(_ device: AVSingleAudioDevice, file: AVAudioFile) {
		self.device = device
		duration = TimeInterval(file.length) / file.processingFormat.sampleRate
				
        super.init()
		
		device.player.didFinishPlaying = { [weak self] in
			self.map { $0.delegate?.emitterDidStop($0) }
		}
    }
		
	var currentTime: TimeInterval? { device.player.currentTime }
	
	var isPlaying: Bool { device.player.isPlaying }
    
	var volume: Double {
		get { Double(device.player.volume) }
		set { device.player.volume = Float(newValue) }
	}
	
    func move(to time: TimeInterval) {
		device.player.move(to: time)
		delegate?.emitterUpdatedState(self)
    }
	
	func move(by time: TimeInterval) throws {
		device.player.move(by: time)
		delegate?.emitterUpdatedState(self)
	}
	    
    func start() {
		device.player.play()
        delegate?.emitterUpdatedState(self)
    }
    
    func stop() {
		device.player.stop()
        delegate?.emitterUpdatedState(self)
    }
}
