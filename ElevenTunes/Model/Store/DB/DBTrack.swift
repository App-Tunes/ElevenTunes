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

public class DBLibraryTrack: AnyTrack {
    let library: Library
    let cache: DBTrack
    let backend: AnyTrack?
    
    var backendObservers = Set<AnyCancellable>()

    init(library: Library, cache: DBTrack, backend: AnyTrack?) {
        self.library = library
        self.cache = cache
        self.backend = backend
    }
    
    public var asToken: TrackToken { fatalError() }
    
    public var id: String { cache.objectID.description }
    
    public var origin: URL? { backend?.origin ?? nil }
    
    public var icon: Image { backend?.icon ?? Image(systemName: "questionmark") }
    public var accentColor: Color { backend?.accentColor ?? .primary }
    
    public func cacheMask() -> AnyPublisher<TrackContentMask, Never> {
        guard backend != nil else {
            // If no backend, we don't even have a cache
            return Just(TrackContentMask.minimal).eraseToAnyPublisher()
        }
        
        return cache.$cacheMaskP.eraseToAnyPublisher()
    }
    
    public func attributes() -> AnyPublisher<TypedDict<TrackAttribute>, Never> {
        cache.$attributesP.eraseToAnyPublisher()
    }
    
    public func artists() -> AnyPublisher<[AnyPlaylist], Never> {
        backend?.artists() ?? Just([]).eraseToAnyPublisher()
    }
    
    public func album() -> AnyPublisher<AnyPlaylist?, Never> {
        backend?.album() ?? Just(nil).eraseToAnyPublisher()
    }

    public func invalidateCaches(_ mask: TrackContentMask) {
        if let backend = backend {
            let clearBits = cache.backendCacheMask & mask.rawValue
            if clearBits != 0 {
                cache.backendCacheMask -= clearBits
            }
            
            backend.invalidateCaches(mask)
        }
    }
    
    public func emitter(context: PlayContext) -> AnyPublisher<AnyAudioEmitter, Error> {
        backend?.emitter(context: context)
            ?? Fail(error: EmitterFail.noBackend).eraseToAnyPublisher()
    }
}

@objc(DBTrack)
public class DBTrack: NSManagedObject {
    @Published var backendP: TrackToken?
    
    @Published var cacheMaskP: TrackContentMask = []
    @Published var attributesP: TypedDict<TrackAttribute> = .init()
            
    public override func awakeFromFetch() { initialSetup() }
    public override func awakeFromInsert() { initialSetup() }

    func initialSetup() {
        backendP = backend
        
        cacheMaskP = TrackContentMask(rawValue: backendCacheMask)
        attributesP = cachedAttributes
    }
}
