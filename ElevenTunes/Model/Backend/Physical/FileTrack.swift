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

public class FileTrack: RemoteTrack {
    public var url: URL
    
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
        return type.conforms(to: .audio) || type.conforms(to: .audiovisualContent)
    }

    static func create(fromURL url: URL) throws -> FileTrack {
        _ = try AVAudioFile(forReading: url) // Just so we know it's readable
        return FileTrack(url)
    }
        
    public override func emitter() -> AnyPublisher<AnyAudioEmitter, Error> {
        let url = self.url
        return Future {
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            return AVFoundationAudioEmitter(player)
        }
            .eraseToAnyPublisher()
    }
}

extension FileTrack {
    enum CodingKeys: String, CodingKey {
      case url
    }
}
