//
//  FileVideo.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 28.12.20.
//

import Foundation
import CoreData
import UniformTypeIdentifiers
import Combine
import AVFoundation
import SwiftUI

public struct AVTrackToken: TrackToken {
	enum InterpretationError: Error {
		case missing
	}

	let url: URL
	let isVideo: Bool
	
	public var id: String { url.absoluteString }
	public var origin: URL? { url }
	
	static func understands(url: URL) -> Bool {
		guard let type = UTType(filenameExtension: url.pathExtension) else {
			return false
		}
		return type.conforms(to: .audiovisualContent)
	}

	static func create(fromURL url: URL) throws -> AVTrackToken {
		_ = try AVAudioFile(forReading: url) // Just so we know it's readable
		let type = try UTType(filenameExtension: url.pathExtension).unwrap(orThrow: InterpretationError.missing)
		let isVideo = type.conforms(to: .movie)
		
		return AVTrackToken(url: url, isVideo: isVideo)
	}
	
	public func expand(_ context: Library) throws -> AnyTrack {
		AVTrack(url, isVideo: isVideo)
	}
}

public final class AVTrack: RemoteTrack {
	enum AnalysisError: Error {
		case notImplemented
	}
	
	enum TagLibError: Error {
		case cannotRead
	}
	
	public let url: URL
	public let isVideo: Bool

	var cache: DBAVTrack? = nil

	enum Request {
		case url, analyze, taglib
	}
	
	let mapper = Requests(relation: [
		.url: [],
		.taglib: [.title, .key, .tempo, .previewImage, .artists, .album],
		.analyze: []
	])

	init(_ url: URL, isVideo: Bool) {
		self.url = url
		self.isVideo = isVideo
		mapper.delegate = self
		mapper.offer(.url, update: loadURL())
	}
	 
	convenience init(cache: DBAVTrack) {
		self.init(cache.url, isVideo: cache.isVideo)
		// It's reasonable to assume for the moment
		// that the track is always read on import, so
		// when we're created from DB we assume values as valid
//		mapper.attributes.update(cache.owner.attributes.snapshot)
		self.cache = cache
	}
	 
	public var accentColor: Color { SystemUI.color }

    public var icon: Image {
		isVideo ? Image(systemName: "film") : Image(systemName: "music.note")
	}
	
	public var id: String { url.absoluteString }
	
	public var origin: URL? { url }

	func loadURL() -> TrackAttributes.PartialGroupSnapshot {
		do {
			return .init(.unsafe([
				.title: url.lastPathComponent
			]), state: .missing)
		}
		catch let error {
			return .empty(state: .error(error))
		}
	}
	
	public func audioTrack(forDevice device: BranchingAudioDevice) throws -> AnyPublisher<AudioTrack, Error> {
		guard let device = device.av else {
			throw UnsupportedAudioDeviceError()
		}
		
		// TODO Return video emitter when possible
		return Future { [url] in
			let file = try AVAudioFile(forReading: url)
			let singleDevice = try device.prepare(file)
			return AVAudioPlayerEmitter(singleDevice, file: file)
		}
			.eraseToAnyPublisher()
	}
	
	public func supports(_ capability: TrackCapability) -> Bool {
		false
	}
}

extension AVTrack: RequestMapperDelegate {
	func onDemand(_ request: Request) -> AnyPublisher<TrackAttributes.PartialGroupSnapshot, Error> {
		let url = self.url
		
		switch request {
		case .url:
			return Future { self.loadURL() }.eraseToAnyPublisher()
		case .taglib:
			return Future {
				try TagLibFile(url: url).unwrap(orThrow: TagLibError.cannotRead)
			}
			.map { file in
				.init(.unsafe([
					.title: file.title,
					.previewImage: file.image.flatMap { NSImage(data: $0) },
					.tempo: file.bpm.flatMap { Double($0) }.map { Tempo(bpm: $0) },
					.key: file.initialKey.flatMap { MusicalKey.parse($0) },
					.album: file.album.map { TransientAlbum(attributes: .unsafe([
						.title: $0
					])) },
					.artists: file.artist.map {
						let artists = TransientArtist.splitNames($0)
						
						return artists.map {
							TransientArtist(attributes: .unsafe([
								.title: $0
							]))
						}
					}
				]), state: .valid)
			}
			.eraseToAnyPublisher()
		case .analyze:
			return Future {
				let file = EssentiaFile(url: url)
				let analysis = try file.analyze()
				let keyAnalysis = analysis.keyAnalysis!
				let rhythmAnalysis = analysis.rhythmAnalysis!

				return .init(.unsafe([
					// TODO lol parse these separately
					.key: MusicalKey.parse("\(keyAnalysis.key)\(keyAnalysis.scale)"),
					.tempo: Tempo(bpm: rhythmAnalysis.bpm)
				]), state: .valid)
			}
				.eraseError().eraseToAnyPublisher()
		}
	}
	
	func onUpdate(_ snapshot: VolatileAttributes<TrackAttribute, String>.PartialGroupSnapshot, from request: Request) {
		// TODO
	}
}

extension AVTrack: BranchableTrack {
	func store(in track: DBTrack) throws -> DBTrack.Representation {
		guard
			let context = track.managedObjectContext,
			let model = context.persistentStoreCoordinator?.managedObjectModel,
			let trackModel = model.entitiesByName["DBAVTrack"]
		else {
			fatalError("Failed to find model in MOC")
		}

		let cache = DBAVTrack(entity: trackModel, insertInto: context)
		cache.url = url
		cache.isVideo = isVideo
		
		track.avRepresentation = cache
		
		self.cache = cache
		
		return .av
	}
}
