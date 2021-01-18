//
//  AVAudioTrack.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 09.01.21.
//

import Foundation
import SwiftUI
import Combine
import UniformTypeIdentifiers
import AVFoundation

public class AVAudioTrackToken: FileTrackToken {
	static func understands(url: URL) -> Bool {
		guard let type = UTType(filenameExtension: url.pathExtension) else {
			return false
		}
		return type.conforms(to: .audio)
	}

	static func create(fromURL url: URL) throws -> FileVideoToken {
		_ = try AVAudioFile(forReading: url) // Just so we know it's readable
		return FileVideoToken(url)
	}

	override func expand(_ context: Library) -> AnyTrack {
		AVAudioTrack(self)
	}
}

public final class AVAudioTrack: FileTrack {
	public let token: AVAudioTrackToken
	
	enum Request {
		case url, analyze
	}
	
	let mapper = Requests(relation: [
		.url: [.title],
		.analyze: [.bpm, .key]
	])

	init(_ token: AVAudioTrackToken) {
		self.token = token
		loadURL()
		mapper.requestFeatureSet.insert(.url)
	}
	
	public var icon: Image { Image(systemName: "video") }

//    public func load(atLeast mask: TrackContentMask) {
//        contentSet.promise(mask) { promise in
//            promise.fulfilling(.minimal) {
//                _attributes.value[TrackAttribute.title] = token.url.lastPathComponent
//            }
//        }
//    }
}

extension AVAudioTrack: RequestMapperDelegate {
	func onDemand(_ request: Request) -> AnyPublisher<VolatileAttributes<TrackAttribute, TrackVersion>.PartialGroupSnapshot, Error> {
		// TODO
		fatalError()
	}
}
