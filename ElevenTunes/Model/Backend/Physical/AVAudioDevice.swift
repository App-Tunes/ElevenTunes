//
//  AVAudioDevice.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 21.03.21.
//

import AVFoundation
import SwiftUI
import TunesLogic
import TunesUI

public class AVAudioDevice: AudioDevice {
	static let systemDefault = AVAudioDevice(deviceID: nil)
	
	let deviceID: AudioDeviceID?
	
	init(deviceID: AudioDeviceID?) {
		self.deviceID = deviceID
	}
	
	func prepare(_ file: AVAudioFile) throws -> AVSingleAudioDevice {
		let device = AVSingleAudioDevice(player: .init(file: file))

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
			
			if error != .zero {
				throw CoreAudioLogic.OSError(code: error)
			}
		}

		device.player.players.forEach {
			device.engine.attach($0)
			device.engine.connect($0, to: device.engine.mainMixerNode, format: file.processingFormat)
		}
		device.player.prepare()
		
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
		
		guard let count = try? CoreAudioLogic.getObjectPropertyCount(
			object: deviceID,
			address: address,
			forType: (CFString?).self
		) else {
			return false
		}

		return (try? CoreAudioLogic.withObjectProperty(
			object: deviceID,
			address: address,
			type: AudioBufferList.self,
			count: count,
			map: {
				UnsafeMutableAudioBufferListPointer($0)
					.anySatisfy { $0.mNumberChannels > 0 }
			}
		)) ?? false
	}

	var uid: String? {
		guard let deviceID = deviceID else {
			return "System Default"
		}

		return try? CoreAudioLogic.getObjectProperty(
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

		return try? CoreAudioLogic.getObjectProperty(
			object: deviceID,
			address: .init(
				selector: kAudioDevicePropertyDeviceNameCFString,
				scope: kAudioObjectPropertyScopeGlobal
			),
			type: CFString.self
		) as String
	}
	
	var isHidden: Bool {
		guard let id = deviceID ?? CoreAudioLogic.defaultOutputDevice else {
			return true
		}
		
		return (try? CoreAudioLogic.getObjectProperty(
			object: id,
			address: .init(
				selector: kAudioDevicePropertyIsHidden,
				scope: kAudioObjectPropertyScopeOutput
			),
			type: UInt32.self
		) > 0) ?? true
	}
	
	public var transportType: UInt32? {
		guard let id = deviceID ?? CoreAudioLogic.defaultOutputDevice else {
			return nil
		}

		return try? CoreAudioLogic.getObjectProperty(
			object: id,
			address: .init(
				selector: kAudioDevicePropertyTransportType,
				scope: kAudioObjectPropertyScopeGlobal
			),
			type: UInt32.self
		)
	}
		
	public var icon: Image {
		if deviceID == nil {
			return Image(systemName: "circle")
		}
		
		switch transportType {
		case kAudioDeviceTransportTypeBluetooth, kAudioDeviceTransportTypeBluetoothLE:
			return Image(systemName: "wave.3.right.circle")
		case kAudioDeviceTransportTypeBuiltIn:
			return Image(systemName: "laptopcomputer")
		case kAudioDeviceTransportTypeAggregate, kAudioDeviceTransportTypeAutoAggregate, kAudioDeviceTransportTypeVirtual:
			return Image(systemName: "square.stack.3d.down.forward")
		case kAudioDeviceTransportTypeAirPlay:
			return Image(systemName: "airplayaudio")
		default:
			return Image(systemName: "hifispeaker")
		}
	}
	
	public var volume: Double {
		get {
			(deviceID ?? CoreAudioLogic.defaultOutputDevice).flatMap {
				CoreAudioLogic.volume(ofDevice: UInt32($0))
			}.flatMap(Double.init) ?? 0
		}
		set {
			objectWillChange.send()
			(deviceID ?? CoreAudioLogic.defaultOutputDevice).map {
				CoreAudioLogic.setVolume(ofDevice: UInt32($0), Float(newValue))
			}
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
	let player: AVSeekableAudioPlayerNode
	
	init(player: AVSeekableAudioPlayerNode) {
		self.player = player
	}
}
