//
//  AVAudioDeviceProvider.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 23.03.21.
//

import Foundation

class AVAudioDeviceProvider: AudioDeviceProxy {
	let context: PlayContext

	init(context: PlayContext) {
		self.context = context
		
//		AKManager.addObserver(self, forKeyPath: #keyPath(AKManager.outputDevices), options: [.new], context: nil)
//		AKManager.addObserver(self, forKeyPath: #keyPath(AKManager.outputDevice), options: [.new], context: nil)
	}
	
//	override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
//		print("Change!")
//		objectWillChange.send()
//	}
	
	lazy var options: [AVAudioDevice] = [.systemDefault] + AudioDeviceFinder.findDevices()
	
	var current: AVAudioDevice? {
		get { context.avOutputDevice }
		set {
			objectWillChange.send()
			context.avOutputDevice = newValue
		}
	}
}
