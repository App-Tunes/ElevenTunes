//
//  AnyPlaylist.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 25.12.20.
//

import Foundation
import SwiftUI
import Combine

public enum LoadLevel: Int16, Comparable {
    case none, minimal, detailed
}

public protocol AnyPlaylist: AnyObject {
    var id: String { get }
    var icon: Image { get }
    
    var anyTracks: AnyPublisher<[AnyTrack], Never> { get }
    var anyChildren: AnyPublisher<[AnyPlaylist], Never> { get }

    var loadLevel: AnyPublisher<LoadLevel, Never> { get }
    
    var attributes: AnyPublisher<TypedDict<PlaylistAttribute>, Never> { get }

    @discardableResult
    func load(atLeast level: LoadLevel, deep: Bool, context: PlayContext) -> Bool

    @discardableResult
    func add(tracks: [PersistentTrack]) -> Bool
    
    @discardableResult
    func add(children: [PersistentPlaylist]) -> Bool
}

extension AnyPlaylist {
    @discardableResult
    public func load(atLeast level: LoadLevel, context: PlayContext) -> Bool {
        load(atLeast: level, deep: false, context: context)
    }
}

public class PersistentPlaylist: NSObject, AnyPlaylist, Codable {
    public var id: String { fatalError() }
    public var icon: Image { Image(systemName: "music.note.list") }
    
    public var loadLevel: AnyPublisher<LoadLevel, Never> { fatalError() }
    
    public var attributes: AnyPublisher<TypedDict<PlaylistAttribute>, Never> { fatalError() }
    
    @discardableResult
    public func add(tracks: [PersistentTrack]) -> Bool { false }
    
    @discardableResult
    public func add(children: [PersistentPlaylist]) -> Bool { false }
    
    @discardableResult
    public func load(atLeast level: LoadLevel, deep: Bool, context: PlayContext) -> Bool {
        fatalError()
    }

    var tracks: AnyPublisher<[PersistentTrack], Never> { fatalError() }
    var children: AnyPublisher<[PersistentPlaylist], Never> { fatalError() }
}

extension PersistentPlaylist {
    public var anyTracks: AnyPublisher<[AnyTrack], Never> {
        tracks.map { $0 as [AnyTrack] }
            .eraseToAnyPublisher()
    }
    
    public var anyChildren: AnyPublisher<[AnyPlaylist], Never> {
        children.map { $0 as [AnyPlaylist] }
            .eraseToAnyPublisher()
    }
}

class PlaylistBackendTypedCodable: TypedCodable<String> {
    static let _registry = CodableRegistry<String>()
        .register(TransientPlaylist.self, for: "transient")
        .register(DirectoryPlaylist.self, for: "directory")
        .register(M3UPlaylist.self, for: "m3u")
        .register(SpotifyPlaylist.self, for: "spotify")

    override class var registry: CodableRegistry<String> { _registry }
}

extension NSValueTransformerName {
    static let playlistBackendName = NSValueTransformerName(rawValue: "PlaylistBackendTransformer")
}

@objc(PlaylistBackendTransformer)
class PlaylistBackendTransformer: TypedJSONCodableTransformer<String, PlaylistBackendTypedCodable> {}
