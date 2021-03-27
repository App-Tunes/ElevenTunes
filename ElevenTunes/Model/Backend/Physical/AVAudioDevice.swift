//
//  AVAudioDevice.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 21.03.21.
//

import AVFoundation
import SwiftUI

public class AVAudioDevice: AudioDevice {
	static let systemDefault = AVAudioDevice(deviceID: nil)
	
	let deviceID: AudioDeviceID?
	
	init(deviceID: AudioDeviceID?) {
		self.deviceID = deviceID
	}
	
	func prepare(_ file: AVAudioFile) throws -> AVSingleAudioDevice {
		let device = AVSingleAudioDevice()

		if let deviceID = self.deviceID {
			var deviceID = deviceID
			let error = AudioUnitSetProperty(
				device.engine.outputNode.audioUnit!,
				kAudioOutputUnitProperty_CurrentDevice,
				kAudioUnitScope_Global,
				0,
				&deviceID,
				UInt32(MemoryLayout<String>.size)
			)
		}

		device.engine.attach(device.player)
		device.engine.connect(device.player, to: device.engine.mainMixerNode, format: file.processingFormat)
		device.engine.prepare()

		try device.engine.start()
		
		return device
	}
	
	var isDefault: Bool { deviceID == nil }
	
	var hasOutput: Bool {
		guard let deviceID = deviceID else {
			return true
		}
		
		let address = AudioObjectPropertyAddress(
			selector: kAudioDevicePropertyStreamConfiguration,
			scope: kAudioDevicePropertyScopeOutput
		)
		
		guard let count = try? CoreAudioTT.getObjectPropertyCount(
			object: deviceID,
			address: address,
			forType: (CFString?).self
		) else {
			return false
		}

		guard let list = try? CoreAudioTT.getObjectPointer(
			object: deviceID,
			address: address,
			type: AudioBufferList.self,
			count: count
		) else {
			return false
		}

		return UnsafeMutableAudioBufferListPointer(list)
			.anySatisfy { $0.mNumberChannels > 0 }
	}

	var uid: String? {
		guard let deviceID = deviceID else {
			return "System Default"
		}

		return try? CoreAudioTT.getObjectProperty(
			object: deviceID,
			address: .init(
				selector: kAudioDevicePropertyDeviceUID,
				scope: kAudioObjectPropertyScopeGlobal,
				element: kAudioObjectPropertyElementMaster
			),
			type: CFString.self
		) as String
	}

	public var name: String? {
		guard let deviceID = deviceID else {
			return "System Default"
		}

		return try? CoreAudioTT.getObjectProperty(
			object: deviceID,
			address: .init(
				selector: kAudioDevicePropertyDeviceNameCFString,
				scope: kAudioObjectPropertyScopeGlobal
			),
			type: CFString.self
		) as String
	}
	
	var isHidden: Bool {
		guard let id = deviceID ?? CoreAudioTT.defaultOutputDevice else {
			return true
		}
		
		return (try? CoreAudioTT.getObjectProperty(
			object: id,
			address: .init(
				selector: kAudioDevicePropertyIsHidden,
				scope: kAudioDevicePropertyScopeOutput
			),
			type: UInt32.self
		) > 0) ?? true
	}
	
	public var icon: Image {
		switch deviceID {
		case nil:
			return Image(systemName: "circle")
		default:
			return Image(systemName: "hifispeaker")
		}
	}
	
	public var volume: Double {
		get {
			(deviceID ?? CoreAudioTT.defaultOutputDevice).flatMap {
				CoreAudioTT.volume(ofDevice: UInt32($0))
			}.flatMap(Double.init) ?? 0
		}
		set {
			objectWillChange.send()
			(deviceID ?? CoreAudioTT.defaultOutputDevice).map {
				CoreAudioTT.setVolume(ofDevice: UInt32($0), Float(newValue))
			}
		}
	}
}

class AudioDeviceFinder {
	static func findDevices() -> [AVAudioDevice] {
		do {
			let deviceIDS = try CoreAudioTT.getObjectPropertyList(
				object: AudioObjectID(kAudioObjectSystemObject),
				address: .init(
					selector: kAudioHardwarePropertyDevices,
					scope: kAudioObjectPropertyScopeGlobal,
					element: kAudioObjectPropertyElementMaster
				),
				type: AudioDeviceID.self
			)
			
			return deviceIDS.compactMap {
				let audioDevice = AVAudioDevice(deviceID: $0)
				return audioDevice.hasOutput && !audioDevice.isHidden ? audioDevice : nil
			}
		}
		catch let error {
			print(error.localizedDescription)
			return []
		}
	}
}

extension AVAudioDevice: Equatable {
	public static func == (lhs: AVAudioDevice, rhs: AVAudioDevice) -> Bool {
		lhs.deviceID == rhs.deviceID
	}
}

public class AVSingleAudioDevice {
	let engine = AVAudioEngine()
	let player = AVAudioPlayerNode()
}
