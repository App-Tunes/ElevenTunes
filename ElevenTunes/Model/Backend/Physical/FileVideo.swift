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

public class FileVideoToken: FileTrackToken {
    static func understands(url: URL) -> Bool {
        guard let type = UTType(filenameExtension: url.pathExtension) else {
            return false
        }
        return type.conforms(to: .audiovisualContent) && !type.conforms(to: .audio)
    }

    static func create(fromURL url: URL) throws -> FileVideoToken {
        _ = try AVAudioFile(forReading: url) // Just so we know it's readable
        return FileVideoToken(url)
    }
    
    override func expand(_ context: Library) -> AnyTrack {
        FileVideo(self)
    }
}

public final class FileVideo: FileTrack {
    public let token: FileVideoToken
    
	enum Request {
		case url, analyze
	}
	
	let mapper = Requests(relation: [
		.url: [.title],
		.analyze: [.bpm, .key]
	])

    init(_ token: FileVideoToken) {
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

extension FileVideo: RequestMapperDelegate {
	func onDemand(_ request: Request) -> AnyPublisher<VolatileAttributes<TrackAttribute, TrackVersion>.PartialGroupSnapshot, Error> {
		// TODO
		fatalError()
	}
}
