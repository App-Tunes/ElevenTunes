//
//  AVAudioDeviceProvider.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 23.03.21.
//

import Foundation

class AVAudioDeviceProvider: AudioDeviceProxy {
	lazy var options: [AVAudioDevice] = [.systemDefault] + AudioDeviceFinder.findDevices()
}
