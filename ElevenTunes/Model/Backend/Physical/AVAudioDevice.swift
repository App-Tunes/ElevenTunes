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
		
		var address:AudioObjectPropertyAddress = AudioObjectPropertyAddress(
			mSelector:AudioObjectPropertySelector(kAudioDevicePropertyStreamConfiguration),
			mScope:AudioObjectPropertyScope(kAudioDevicePropertyScopeOutput),
			mElement:0)

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
			return nil
		}

		var address:AudioObjectPropertyAddress = AudioObjectPropertyAddress(
			mSelector:AudioObjectPropertySelector(kAudioDevicePropertyDeviceUID),
			mScope:AudioObjectPropertyScope(kAudioObjectPropertyScopeGlobal),
			mElement:AudioObjectPropertyElement(kAudioObjectPropertyElementMaster))

		var name:CFString? = nil
		var propsize:UInt32 = UInt32(MemoryLayout<CFString?>.size)
		let result:OSStatus = AudioObjectGetPropertyData(deviceID, &address, 0, nil, &propsize, &name)
		if (result != 0) {
			return nil
		}

		return name as String?
	}

	var name: String? {
		guard let deviceID = deviceID else {
			return "System Default"
		}

		var address:AudioObjectPropertyAddress = AudioObjectPropertyAddress(
			mSelector:AudioObjectPropertySelector(kAudioDevicePropertyDeviceNameCFString),
			mScope:AudioObjectPropertyScope(kAudioObjectPropertyScopeGlobal),
			mElement:AudioObjectPropertyElement(kAudioObjectPropertyElementMaster))

		var name:CFString? = nil
		var propsize:UInt32 = UInt32(MemoryLayout<CFString?>.size)
		let result:OSStatus = AudioObjectGetPropertyData(deviceID, &address, 0, nil, &propsize, &name)
		if (result != 0) {
			return nil
		}

		return name as String?
	}
	
	var icon: String {
		guard let deviceID = deviceID else {
			return "􀀀"
		}
		
		if deviceID == 46 { return "􀙗" }
		return "􀝎"
	}
	
	var volume: Double {
		get {
			(deviceID ?? CoreAudioTT.defaultOutputDevice).flatMap {
				CoreAudioTT.volume(ofDevice: UInt32($0))
			}.flatMap(Double.init) ?? 0
		}
		set {
			(deviceID ?? CoreAudioTT.defaultOutputDevice).map {
				CoreAudioTT.setVolume(ofDevice: UInt32($0), Float(newValue))
			}
		}
	}
}

class CoreAudioTT {
	struct OSError: Error {
		var code: OSStatus
	}
	
	static func device(ofUnit unit: AudioUnit) -> UInt32? {
		var deviceID: AudioDeviceID = 0
		var propertySize: UInt32 = UInt32(MemoryLayout.size(ofValue: deviceID))
		
		let error = AudioUnitGetProperty(unit,
							 kAudioOutputUnitProperty_CurrentDevice,
							 kAudioUnitScope_Global, 0,
							 &deviceID,
							 &propertySize)
		
		if error != 0 {
			print("Could not get current device: \(error)")
			return nil
		}
		
		return deviceID
	}
	
	static func volume(ofDevice device: UInt32, channel: UInt32? = nil) -> Float? {
		do {
			let channels = channel.map { $0...$0 } ?? 1...2
			let volumes = try channels.map { try getObjectProperty(
				object: device,
				selector: kAudioDevicePropertyVolumeScalar,
				scope: kAudioDevicePropertyScopeOutput,
				example: Float32(),
				channel: $0
			)}
			return volumes.max()
		}
		catch let error {
			print("Could not get volume: \(error)")
		}
		
		return nil
	}
		
	static func setVolume(ofDevice device: UInt32, _ volume: Float) {
		do {
			let channels: ClosedRange<UInt32> = 1...2
			let volumes = channels.map { Self.volume(ofDevice: device, channel: $0) ?? 0 }
			let max = volumes.max() ?? 1
			let ratios = volumes.map { max > 0 ? $0 / max : 1 }
			
			for (ratio, channel) in zip(ratios, channels) {
				try setObjectProperty(
					object: device,
					selector: kAudioDevicePropertyVolumeScalar,
					scope: kAudioDevicePropertyScopeOutput,
					value: volume * ratio,
					channel: channel
				)
			}
		}
		catch let error {
			print("Could not set volume: \(error)")
		}
	}
		
	static var defaultOutputDevice: UInt32? {
		do {
			return try getObjectProperty(
				object: AudioObjectID(kAudioObjectSystemObject),
				selector: kAudioHardwarePropertyDefaultSystemOutputDevice,
				scope: kAudioObjectPropertyScopeGlobal,
				example: AudioDeviceID()
			)
		}
		catch let error {
			print("Could not get default device: \(error)")
		}
		
		return nil
	}
	
	static func getObjectProperty<T>(object: AudioObjectID, selector: AudioObjectPropertySelector, scope: AudioObjectPropertyScope, example: T, channel: UInt32 = 0) throws -> T {
		var propertySize = UInt32(MemoryLayout<T>.size)
		var property = example // TODO Instead pass type lol
		var propertyAddress = AudioObjectPropertyAddress(mSelector: selector, mScope: scope, mElement: channel)

		let error = AudioObjectGetPropertyData(object, &propertyAddress, 0, nil, &propertySize, &property)

		guard error == 0 else {
			throw OSError(code: error)
		}
		
		return property
	}
	
	static func setObjectProperty<T>(object: AudioObjectID, selector: AudioObjectPropertySelector, scope: AudioObjectPropertyScope, value: T, channel: UInt32 = 0) throws {
		var property = value
		var propertyAddress = AudioObjectPropertyAddress(mSelector: selector, mScope: scope, mElement: channel)
		let propertySize = UInt32(MemoryLayout<T>.size)

		let error = AudioObjectSetPropertyData(object, &propertyAddress, 0, nil, propertySize, &property)

		if error != 0 {
			throw OSError(code: error)
		}
	}
}

class AudioDeviceFinder {
	static func findDevices() -> [AVAudioDevice] {
		var propsize:UInt32 = 0

		var address:AudioObjectPropertyAddress = AudioObjectPropertyAddress(
			mSelector:AudioObjectPropertySelector(kAudioHardwarePropertyDevices),
			mScope:AudioObjectPropertyScope(kAudioObjectPropertyScopeGlobal),
			mElement:AudioObjectPropertyElement(kAudioObjectPropertyElementMaster))

		var result:OSStatus = AudioObjectGetPropertyDataSize(AudioObjectID(kAudioObjectSystemObject), &address, UInt32(MemoryLayout<AudioObjectPropertyAddress>.size), nil, &propsize)

		if (result != 0) {
			print("Error \(result) from AudioObjectGetPropertyDataSize")
			return []
		}

		let numDevices = Int(propsize / UInt32(MemoryLayout<AudioDeviceID>.size))

		var devids = [AudioDeviceID]()
		for _ in 0..<numDevices {
			devids.append(AudioDeviceID())
		}

		result = AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &propsize, &devids);
		if (result != 0) {
			print("Error \(result) from AudioObjectGetPropertyData")
			return []
		}

		return devids.compactMap {
			let audioDevice = AVAudioDevice(deviceID: $0)
			return audioDevice.hasOutput ? audioDevice : nil
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
