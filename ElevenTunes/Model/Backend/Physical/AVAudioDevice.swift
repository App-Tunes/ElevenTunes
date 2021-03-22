//
//  AVAudioDevice.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 21.03.21.
//

import AVFoundation

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
		
		var address = AudioObjectPropertyAddress(
			selector: kAudioDevicePropertyStreamConfiguration,
			scope: kAudioDevicePropertyScopeOutput
		)

		var propsize:UInt32 = UInt32(MemoryLayout<CFString?>.size);
		var result:OSStatus = AudioObjectGetPropertyDataSize(deviceID, &address, 0, nil, &propsize);
		if (result != 0) {
			return false;
		}

		let bufferList = UnsafeMutablePointer<AudioBufferList>.allocate(capacity:Int(propsize))
		result = AudioObjectGetPropertyData(deviceID, &address, 0, nil, &propsize, bufferList);
		if (result != 0) {
			return false
		}

		let buffers = UnsafeMutableAudioBufferListPointer(bufferList)
		for bufferNum in 0..<buffers.count {
			if buffers[bufferNum].mNumberChannels > 0 {
				return true
			}
		}

		return false
	}

	var uid: String? {
		guard let deviceID = deviceID else {
			return "System Default"
		}

		guard let uid = try? CoreAudioTT.getObjectProperty(
			object: deviceID,
			address: .init(
				selector: kAudioDevicePropertyDeviceUID,
				scope: kAudioObjectPropertyScopeGlobal,
				element: kAudioObjectPropertyElementMaster
			),
			type: CFString.self
		) else {
			return nil
		}
		
		return uid as String
	}

	public override var name: String {
		guard let deviceID = deviceID else {
			return "System Default"
		}

		guard let name = try? CoreAudioTT.getObjectProperty(
			object: deviceID,
			address: .init(
				selector: kAudioDevicePropertyDeviceNameCFString,
				scope: kAudioObjectPropertyScopeGlobal
			),
			type: CFString.self
		) else {
			return "Unknown Device"
		}
		
		return name as String
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
	
	var icon: String {
		guard let deviceID = deviceID else {
			return "􀀀"
		}
		
		return "􀝎"
	}
	
	public override var volume: Double {
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
		var propsize: UInt32 = 0

		var address = AudioObjectPropertyAddress(
			selector: kAudioHardwarePropertyDevices,
			scope: kAudioObjectPropertyScopeGlobal,
			element: kAudioObjectPropertyElementMaster
		)

		let result:OSStatus = AudioObjectGetPropertyDataSize(AudioObjectID(kAudioObjectSystemObject), &address, UInt32(MemoryLayout<AudioObjectPropertyAddress>.size), nil, &propsize)

		if (result != 0) {
			print("Error \(result) from AudioObjectGetPropertyDataSize")
			return []
		}

		let deviceCount = Int(propsize / UInt32(MemoryLayout<AudioDeviceID>.size))

		do {
			let deviceIDS = try CoreAudioTT.getObjectProperty(
				object: AudioObjectID(kAudioObjectSystemObject),
				address: address,
				type: AudioDeviceID.self,
				count: deviceCount
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
