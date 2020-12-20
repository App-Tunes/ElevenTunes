//
//  TrackBackend.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 19.12.20.
//

import Foundation
import AVFoundation
import Combine

protocol TrackBackend {
    func audio(for track: Track) -> AnyPublisher<AnyAudioEmitter, Error>
}
