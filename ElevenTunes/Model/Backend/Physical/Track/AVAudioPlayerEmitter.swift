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
	let file: AVAudioFile
	let format: AVAudioFormat
	let duration: TimeInterval?

	var startTime: TimeInterval = 0
	var isSwapping: Bool = false
	
    weak var delegate: AudioTrackDelegate? = nil

	init(_ device: AVSingleAudioDevice, file: AVAudioFile) {
		self.device = device
		self.file = file
		format = file.processingFormat
		duration = TimeInterval(file.length) / format.sampleRate
		
        super.init()
    }
		
	var _currentTime: TimeInterval {
		guard
			let nodeTime = device.player.lastRenderTime,
			let playerTime = device.player.playerTime(forNodeTime: nodeTime)
		else {
			return startTime
		}
		
		return startTime + TimeInterval(playerTime.sampleTime) / TimeInterval(format.sampleRate)
	}
    
    var currentTime: TimeInterval? { _currentTime }
	
	var isPlaying: Bool { device.player.isPlaying }
    
	var volume: Double {
		get { Double(device.player.volume) }
		set { device.player.volume = Float(newValue) }
	}
	
    func move(to time: TimeInterval) {
		startTime = time

		if device.player.isPlaying {
			isSwapping = true
			device.player.stop()
			isSwapping = false
			_seek()
			device.player.play()
		}
		else {
			_seek()
		}
		
		delegate?.emitterUpdatedState(self)
    }
	
	func _seek() {
		let startSample = max(0, AVAudioFramePosition(floor(startTime * format.sampleRate)))
		
		guard file.length > startSample else {
			delegate?.emitterDidStop(self)
			return
		}

		device.player.scheduleSegment(file, startingFrame: startSample, frameCount: AVAudioFrameCount(file.length), at: nil) { [weak self] in
			guard let self = self else { return }
			// Is this a proper completion?
			guard !self.isSwapping else { return }
			
			self.delegate?.emitterDidStop(self)
		}
	}
    
    func start() {
		device.player.play()
        delegate?.emitterUpdatedState(self)
    }
    
    func stop() {
		startTime = _currentTime
		// We could pause, but we never know when the user wants to resume anyway
		isSwapping = true
		device.player.stop()
		isSwapping = false
		_seek()  // Schedule for resume
        delegate?.emitterUpdatedState(self)
    }
}
