//
//  AVAudioDeviceProvider.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 23.03.21.
//

import Foundation
import SwiftUI

class AVAudioDeviceProvider: AudioDeviceProvider {
	lazy var options: [AVAudioDevice] = [.systemDefault] + AudioDeviceFinder.findDevices()
	
	var icon: Image { Image(systemName: "speaker.wave.2.circle") }
	var color: Color { .primary }
}
