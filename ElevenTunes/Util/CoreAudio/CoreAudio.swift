//
//  CoreAudio.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 22.03.21.
//

import AVFoundation

extension AudioObjectPropertyAddress {
	init(selector: AudioObjectPropertySelector, scope: AudioObjectPropertyScope, element: AudioObjectPropertyElement = 0) {
		self.init(mSelector: selector, mScope: scope, mElement: element)
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
				address: .init(
					selector: kAudioDevicePropertyVolumeScalar,
					scope: kAudioDevicePropertyScopeOutput,
					element: $0
				),
				type: Float32.self
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
					address: .init(
						selector: kAudioDevicePropertyVolumeScalar,
						scope: kAudioDevicePropertyScopeOutput,
						element: channel
					),
					value: volume * ratio
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
				address: .init(
					selector: kAudioHardwarePropertyDefaultSystemOutputDevice,
					scope: kAudioObjectPropertyScopeGlobal
				),
				type: AudioDeviceID.self
			)
		}
		catch let error {
			print("Could not get default device: \(error)")
		}
		
		return nil
	}
	
	static func getObjectPointer<T>(object: AudioObjectID, address: AudioObjectPropertyAddress, type: T.Type, count: Int = 1) throws -> UnsafeMutablePointer<T> {
		var propertySize = UInt32(MemoryLayout<T>.size) * UInt32(count)
		
		var address = address

		let obj = malloc(Int(propertySize))!
		let error = AudioObjectGetPropertyData(object, &address, 0, nil, &propertySize, obj)

		guard error == 0 else { throw OSError(code: error) }
		
		return obj.assumingMemoryBound(to: T.self)
	}
	
	static func getObjectProperty<T>(object: AudioObjectID, address: AudioObjectPropertyAddress, type: T.Type) throws -> T {
		try getObjectPointer(object: object, address: address, type: type).pointee
	}
	
	static func getObjectProperty<T>(object: AudioObjectID, address: AudioObjectPropertyAddress, type: T.Type, count: Int) throws -> [T] {
		let pointer = try getObjectPointer(object: object, address: address, type: type, count: count)
		return Array(UnsafeBufferPointer(start: pointer, count: count))
	}
	
	static func setObjectProperty<T>(object: AudioObjectID, address: AudioObjectPropertyAddress, value: T) throws {
		var property = value
		var address = address
		let propertySize = UInt32(MemoryLayout<T>.size)

		let error = AudioObjectSetPropertyData(object, &address, 0, nil, propertySize, &property)

		if error != 0 {
			throw OSError(code: error)
		}
	}
}
