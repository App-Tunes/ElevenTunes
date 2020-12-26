//
//  DBTrack+CoreDataClass.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 26.12.20.
//
//

import Foundation
import CoreData
import Combine

enum EmitterFail: Error {
    case noBackend
}

@objc(DBTrack)
public class DBTrack: NSManagedObject, AnyTrack {
    public var id: String { objectID.description }
    
    public var loadLevel: AnyPublisher<LoadLevel, Never> {
        backend?.loadLevel ?? Just(.detailed).eraseToAnyPublisher()
    }

    public var attributes: AnyPublisher<TypedDict<TrackAttribute>, Never> {
        backend?.attributes ?? Just(.init()).eraseToAnyPublisher()
    }

    public func emitter() -> AnyPublisher<AnyAudioEmitter, Error> {
        backend?.emitter() ?? Fail(error: EmitterFail.noBackend).eraseToAnyPublisher()
    }
    
    @discardableResult
    public func load(atLeast level: LoadLevel) -> Bool {
        return backend?.load(atLeast: level) ?? true
    }
}
