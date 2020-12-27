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
import SwiftUI

enum EmitterFail: Error {
    case noBackend
}

@objc(DBTrack)
public class DBTrack: NSManagedObject, AnyTrack {
    var backendObservers = Set<AnyCancellable>()

    public var id: String { objectID.description }
    
    public var icon: Image { backend?.icon ?? Image(systemName: "questionmark") }
    
    @Published var _loadLevel: LoadLevel = .none
    public var loadLevel: AnyPublisher<LoadLevel, Never> {
        $_loadLevel.eraseToAnyPublisher()
    }
    
    @Published var _attributes: TypedDict<TrackAttribute> = .init()
    public var attributes: AnyPublisher<TypedDict<TrackAttribute>, Never> {
        $_attributes.eraseToAnyPublisher()
    }

    public func emitter() -> AnyPublisher<AnyAudioEmitter, Error> {
        backend?.emitter() ?? Fail(error: EmitterFail.noBackend).eraseToAnyPublisher()
    }
        
    public override func awakeFromFetch() { initialSetup() }
    public override func awakeFromInsert() { initialSetup() }

    func initialSetup() {
        _attributes = cachedAttributes
        _loadLevel = LoadLevel(rawValue: cachedLoadLevel) ?? .none

        refreshObservation()
    }

    @discardableResult
    public func load(atLeast level: LoadLevel) -> Bool {
        guard level > _loadLevel else {
            return true
        }
        
        guard let backend = backend else {
            // Fetch requests have already set the values
            _loadLevel = .detailed
            return true
        }
        
        let currentLoadLevel = LoadLevel(rawValue: cachedLoadLevel) ?? .none
        if currentLoadLevel >= level {
            // We can use DB cache! Yay!
            _loadLevel = currentLoadLevel
            return true
        }
        
        return backend.load(atLeast: level)
    }
}
