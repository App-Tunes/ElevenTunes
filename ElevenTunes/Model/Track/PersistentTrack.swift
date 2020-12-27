//
//  PersistentTrack.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 27.12.20.
//

import Foundation

public class PersistentTrack: NSObject, AnyTrack, Codable {
    public var id: String { fatalError() }
    
    public var icon: Image { Image(systemName: "music.note") }
    
    public var loadLevel: AnyPublisher<LoadLevel, Never> { fatalError() }
    
    public var attributes: AnyPublisher<TypedDict<TrackAttribute>, Never> { fatalError() }
    
    public func emitter(context: PlayContext) -> AnyPublisher<AnyAudioEmitter, Error> {
        fatalError()
    }
    
    public func load(atLeast level: LoadLevel, context: PlayContext) -> Bool {
        fatalError()
    }
}
