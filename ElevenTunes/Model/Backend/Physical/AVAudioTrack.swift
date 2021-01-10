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

public class AVAudioTrack: RemoteTrack {
	let token: AVAudioTrackToken
	
	init(_ token: AVAudioTrackToken) {
		self.token = token
		super.init()
		_attributes.value[TrackAttribute.title] = token.url.lastPathComponent
		contentSet.insert(.minimal)
	}
		 
	public override var id: String { token.id }
	
	public override var accentColor: Color { SystemUI.color }
		
	public override func emitter(context: PlayContext) -> AnyPublisher<AnyAudioEmitter, Error> {
		let url = token.url
		return Future {
			let player = try AVAudioPlayer(contentsOf: url)
			player.prepareToPlay()
			return AVAudioPlayerEmitter(player)
		}
			.eraseToAnyPublisher()
	}
	
	public override func load(atLeast mask: TrackContentMask) {
		contentSet.promise(mask) { promise in
			promise.fulfilling(.minimal) {
				_attributes.value[TrackAttribute.title] = token.url.lastPathComponent
			}
		}
	}
}
