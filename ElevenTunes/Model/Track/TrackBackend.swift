//
//  TrackBackend.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 19.12.20.
//

import Foundation
import AVFoundation
import Combine
import SwiftUI

protocol TrackBackend: AnyObject {
    var frontend: Track? { get set }
    
    var icon: Image? { get }
    
    func emitter() -> AnyPublisher<AnyAudioEmitter, Error>
}
