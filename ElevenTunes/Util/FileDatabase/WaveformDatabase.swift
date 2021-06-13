//
//  WaveformDatabase.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 04.04.21.
//

import Foundation
import TunesUI

class WaveformDatabase<ID: CustomStringConvertible> {
	enum ReadError: Error {
		case noDatabase
	}
	
	// TODO Should be URL, and re-create DB on changes. Harder to implement tho
	let urlProvider: () -> URL?
	
	init(urlProvider: @escaping () -> URL?) {
		self.urlProvider = urlProvider
	}
	
	func url(for id: ID) throws -> URL {
		let baseURL = try urlProvider().unwrap(orThrow: ReadError.noDatabase)
		try FileManager.default.createDirectory(at: baseURL, withIntermediateDirectories: true)
		
		return baseURL
			.appendingPathComponent(id.description)
			.appendingPathExtension(".etunes-waveform")
	}
	
	func toData(_ waveform: Waveform) throws -> Data {
		Data(try ByteWaveform(waveform).serializedData())
	}
	
	func fromData(_ data: Data) throws -> Waveform {
		(try ByteWaveform(serializedData: data)).asWaveform
	}
	
	func get(_ id: ID) throws -> Waveform {
		try fromData(Data(contentsOf: url(for: id)))
	}
	
	func insert(_ waveform: Waveform, for id: ID) throws {
		try toData(waveform).write(to: url(for: id))
	}
	
	func delete(_ id: ID) throws {
		try FileManager.default.removeItem(at: url(for: id))
	}
}
