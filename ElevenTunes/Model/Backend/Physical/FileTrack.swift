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

public class FileTrack: RemoteTrack {
    public var url: URL
    
    init(_ url: URL) {
        self.url = url
        super.init()
        _attributes[TrackAttribute.title] = url.lastPathComponent
        _cacheMask = [.minimal]
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

    static func create(fromURL url: URL) throws -> FileTrack {
        _ = try AVAudioFile(forReading: url) // Just so we know it's readable
        return FileTrack(url)
    }
     
    public override var id: String { url.absoluteString }
        
    public override func emitter(context: PlayContext) -> AnyPublisher<AnyAudioEmitter, Error> {
        let url = self.url
        return Future {
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            return AVFoundationAudioEmitter(player)
        }
            .eraseToAnyPublisher()
    }
    
    public override func load(atLeast mask: TrackContentMask, library: Library) {
        _attributes[TrackAttribute.title] = url.lastPathComponent
        _cacheMask.formUnion(.minimal)
    }
}

extension FileTrack {
    enum CodingKeys: String, CodingKey {
      case url
    }
}
