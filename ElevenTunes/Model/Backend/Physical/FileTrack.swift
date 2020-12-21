//
//  FileBackend.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 19.12.20.
//

import Foundation
import Combine
import AVFoundation
import SwiftUI

class FileTrack: TrackBackend {
    weak var frontend: Track?

    var url: URL
    
    init(_ url: URL) {
        self.url = url
    }

    static func create(fromURL url: URL) throws -> Track {
        _ = try AVAudioFile(forReading: url) // TODO Use file metadata
        let track = Track(FileTrack(url), attributes: .init([
            AnyTypedKey.ttitle.id: url.lastPathComponent
        ]))
        return track
    }
    
    var icon: Image? { nil }
    
    func emitter() -> AnyPublisher<AnyAudioEmitter, Error> {
        let url = self.url
        return Future {
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            return AVFoundationAudioEmitter(player)
        }
            .eraseToAnyPublisher()
    }
}