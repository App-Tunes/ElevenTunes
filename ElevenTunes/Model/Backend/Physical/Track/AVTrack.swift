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

	enum Request {
		case url, analyze, taglib
	}
	
	let mapper = Requests(relation: [
		.url: [],
		.taglib: [.title, .key, .bpm, .previewImage],
		.analyze: [.bpm, .key]
	])

	init(_ url: URL, isVideo: Bool) {
        self.url = url
		self.isVideo = isVideo
		mapper.delegate = self
		mapper.offer(.url, update: loadURL())
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

	public func emitter(context: PlayContext) -> AnyPublisher<AnyAudioEmitter, Error> {
		// TODO Return video emitter when possible
		let url = self.url
		return Future {
			let player = try AVAudioPlayer(contentsOf: url)
			player.prepareToPlay()
			return AVAudioPlayerEmitter(player)
		}
			.eraseToAnyPublisher()
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
					.bpm: file.bpm.flatMap { Double($0) }
				]), state: .valid)
			}
			.eraseToAnyPublisher()
		case .analyze:
			return Just(.empty(state: .error(AnalysisError.notImplemented)))
				.eraseError().eraseToAnyPublisher()
		}
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
		
		return .av
	}
}
