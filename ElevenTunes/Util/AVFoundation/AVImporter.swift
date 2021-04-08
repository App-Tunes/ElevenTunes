//
//  AVImporter.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 09.04.21.
//

import AVFoundation

class AVFoundationImporter {
	var asset: AVAsset
	
	init(_ asset: AVAsset) {
		self.asset = asset
	}
	
	var streamDescription: AudioStreamBasicDescription? {
		guard let track = asset.tracks.first, // Wat? No track??
			let desc = track.formatDescriptions.first else {
				return nil
		}
		
		return CMAudioFormatDescriptionGetStreamBasicDescription(desc as! CMAudioFormatDescription)?.pointee
	}
	
	var duration: CMTime {
		return asset.duration
	}
	
	var bitrate: Float64? {
		guard let info = streamDescription else {
			return nil
		}
		
		return Float64(info.mBitsPerChannel) * info.mSampleRate
	}
	
	var channels: Int {
		guard let info = streamDescription else {
			print("Guessed Channel number!")
			return 1
		}

		return Int(info.mChannelsPerFrame)
	}
	
	func string(withKey: AVMetadataKey, keySpace: AVMetadataKeySpace) -> String? {
		for metadata in AVMetadataItem.metadataItems(from: asset.metadata, withKey: withKey, keySpace: keySpace) {
			if let val = metadata.stringValue {
				return val
			}
		}
		return nil
	}
	
	func number(withKey: AVMetadataKey, keySpace: AVMetadataKeySpace) -> NSNumber? {
		for metadata in AVMetadataItem.metadataItems(from: asset.metadata, withKey: withKey, keySpace: keySpace) {
			if let val = metadata.numberValue {
				return val
			}
		}
		return nil
	}
	
	func data(withKey: AVMetadataKey, keySpace: AVMetadataKeySpace) -> Data? {
		for metadata in AVMetadataItem.metadataItems(from: asset.metadata, withKey: withKey, keySpace: keySpace) {
			if let val = metadata.dataValue {
				return val
			}
		}
		return nil
	}
	
	func image(withKey: AVMetadataKey, keySpace: AVMetadataKeySpace) -> NSImage? {
		if let data = data(withKey: withKey, keySpace: keySpace) {
			if let img = NSImage(data: data) {
				return img
			}
			else {
				print("Failed to read image from data")
			}
		}
		return nil
	}
}
