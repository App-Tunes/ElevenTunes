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
    
    @Published var _cacheMask: TrackContentMask = []
    public var cacheMask: AnyPublisher<TrackContentMask, Never> {
        $_cacheMask.eraseToAnyPublisher()
    }
    
    @Published var _attributes: TypedDict<TrackAttribute> = .init()
    public var attributes: AnyPublisher<TypedDict<TrackAttribute>, Never> {
        $_attributes.eraseToAnyPublisher()
    }

    public func emitter(context: PlayContext) -> AnyPublisher<AnyAudioEmitter, Error> {
        backend?.emitter(context: context)
            ?? Fail(error: EmitterFail.noBackend).eraseToAnyPublisher()
    }
        
    public override func awakeFromFetch() { initialSetup() }
    public override func awakeFromInsert() { initialSetup() }

    func initialSetup() {
        _attributes = cachedAttributes
        if backend != nil {
            _cacheMask = TrackContentMask(rawValue: backendCacheMask)
        }
        else {
            _cacheMask = .minimal
        }

        refreshObservation()
    }

    public func load(atLeast mask: TrackContentMask, library: Library) {
        guard let backend = backend else {
            // Fetch requests have already set the values
            if _cacheMask != [.minimal] {
                _cacheMask = [.minimal]
            }
            return
        }
        
        let missing = mask.subtracting(_cacheMask)
        
        if missing.isEmpty {
            // We have everything we need! Yay!
            return
        }
        
        // Only reload what's missing
        backend.load(atLeast: missing, library: library)
    }
    
    public func invalidateCaches(_ mask: TrackContentMask) {
        if let backend = backend {
            let newMask = _cacheMask.subtracting(mask)
            _cacheMask = newMask
            backendCacheMask = newMask.rawValue
            backend.invalidateCaches(mask)
        }
    }
}
