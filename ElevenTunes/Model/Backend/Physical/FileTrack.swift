//
//  FileTrack+CoreDataClass.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 25.12.20.
//
//

import Foundation
import SwiftUI
import Combine
import AVFoundation

public class FileTrackToken: TrackToken {
    enum CodingKeys: String, CodingKey {
      case url
    }

    public let url: URL
        
    init(_ url: URL) {
        self.url = url
        super.init()
    }
	
	public override var id: String { url.absoluteString }

	override var origin: URL? { url }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        url = try container.decode(URL.self, forKey: .url)
        try super.init(from: decoder)
    }
    
    public override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(url, forKey: .url)
        try super.encode(to: encoder)
    }
}

protocol FileTrack: RemoteTrack where Token: FileTrackToken {
	
}

extension FileTrack {
	public var accentColor: Color { SystemUI.color }
		
	public func emitter(context: PlayContext) -> AnyPublisher<AnyAudioEmitter, Error> {
		// TODO Return video emitter when possible
		let url = token.url
		return Future {
			let player = try AVAudioPlayer(contentsOf: url)
			player.prepareToPlay()
			return AVAudioPlayerEmitter(player)
		}
			.eraseToAnyPublisher()
	}
	
	func loadURL() {
		guard let modificationDate = try? token.url.modificationDate() else {
			return
		}
		
		mapper.attributes.update(.init([
			.title: token.url.lastPathComponent
		]), state: .version(modificationDate.isoFormat))
	}
}
