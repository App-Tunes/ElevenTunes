//
//  AVAudioDevice.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 21.03.21.
//

import AVFoundation

public class AVAudioDevice: AudioDevice {
	func prepare(_ file: AVAudioFile) throws -> AVSingleAudioDevice {
		let device = AVSingleAudioDevice()

		device.engine.attach(device.player)
		device.engine.connect(device.player, to: device.engine.mainMixerNode, format: file.processingFormat)
		device.engine.prepare()

		try device.engine.start()
		
		return device
	}
}

public class AVSingleAudioDevice {
	let engine = AVAudioEngine()
	let player = AVAudioPlayerNode()
}
