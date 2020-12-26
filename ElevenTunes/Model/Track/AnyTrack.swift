//
//  AnyTrack.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 25.12.20.
//

import Foundation
import SwiftUI
import Combine

protocol AnyTrack: AnyObject {
    var id: String { get }
    
    var loadLevel: AnyPublisher<LoadLevel, Never> { get }
    var attributes: AnyPublisher<TypedDict<TrackAttribute>, Never> { get }

    func emitter() -> AnyPublisher<AnyAudioEmitter, Error>
    var icon: Image { get }
    
    @discardableResult
    func load(atLeast level: LoadLevel) -> Bool
}

protocol PersistentTrack: AnyTrack, Codable {
}

extension AnyTrack {
    var icon: Image { Image(systemName: "music.note") }
}

class TrackBackendTransformer: CodableTransformer {
    override class var classes: [AnyClass] { [
        FileTrack.self,
        SpotifyTrack.self
    ]}
}
