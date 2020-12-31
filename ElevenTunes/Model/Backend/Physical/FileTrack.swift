//
//  FileTrack+CoreDataClass.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 25.12.20.
//
//

import Foundation
import CoreData
import UniformTypeIdentifiers
import Combine
import AVFoundation
import SwiftUI

public class FileTrackToken: TrackToken {
    enum CodingKeys: String, CodingKey {
      case url
    }

    public let url: URL
    
    public override var id: String { url.absoluteString }
    
    init(_ url: URL) {
        self.url = url
        super.init()
    }
    
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
    
    static func understands(url: URL) -> Bool {
        guard let type = UTType(filenameExtension: url.pathExtension) else {
            return false
        }
        return type.conforms(to: .audio)
    }

    static func create(fromURL url: URL) throws -> FileTrackToken {
        _ = try AVAudioFile(forReading: url) // Just so we know it's readable
        return FileTrackToken(url)
    }
    
    override func expand(_ context: Library) -> AnyTrack {
        FileTrack(self)
    }
}

public class FileTrack: RemoteTrack {
    let token: FileTrackToken
    
    init(_ token: FileTrackToken) {
        self.token = token
        super.init()
        _attributes.value[TrackAttribute.title] = token.url.lastPathComponent
        contentSet.insert(.minimal)
    }
         
    public override var id: String { token.id }
    
    public override var accentColor: Color { .blue }
        
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
