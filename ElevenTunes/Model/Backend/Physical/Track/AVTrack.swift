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

public final class AVTrack: RemoteTrack {
	enum InterpretationError: Error {
		case missing
	}
	
	enum AnalysisError: Error {
		case notImplemented
	}
	
	public let url: URL
	public let isVideo: Bool

	enum Request {
		case url, analyze
	}
	
	let mapper = Requests(relation: [
		.url: [.title],
		.analyze: [.bpm, .key]
	])

	init(_ url: URL, isVideo: Bool) {
        self.url = url
		self.isVideo = isVideo
		mapper.delegate = self
		mapper.offer(.url, update: loadURL())
    }
     
	static func understands(url: URL) -> Bool {
		guard let type = UTType(filenameExtension: url.pathExtension) else {
			return false
		}
		return type.conforms(to: .audiovisualContent)
	}

	static func create(fromURL url: URL) throws -> AVTrack {
		_ = try AVAudioFile(forReading: url) // Just so we know it's readable
		let type = try UTType(filenameExtension: url.pathExtension).unwrap(orThrow: InterpretationError.missing)
		let isVideo = type.conforms(to: .video)
		
		return AVTrack(url, isVideo: isVideo)
	}

	public var accentColor: Color { SystemUI.color }

    public var icon: Image {
		isVideo ? Image(systemName: "movie") : Image(systemName: "music.note")
	}
	
	public var id: String { url.absoluteString }
	
	public var origin: URL? { url }

	func loadURL() -> TrackAttributes.PartialGroupSnapshot {
		do {
			return .init(.unsafe([
				.title: url.lastPathComponent
			]), state: .valid)
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
	func onDemand(_ request: Request) -> AnyPublisher<VolatileAttributes<TrackAttribute, TrackVersion>.PartialGroupSnapshot, Error> {
		switch request {
		case .analyze:
			return Just(.empty(state: .error(AnalysisError.notImplemented))).eraseError().eraseToAnyPublisher()
		case .url:
			return Future { self.loadURL() }.eraseToAnyPublisher()
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
