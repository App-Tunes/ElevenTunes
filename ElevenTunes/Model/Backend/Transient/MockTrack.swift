//
//  TransientTrack.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 26.12.20.
//

import Foundation
import Combine
import SwiftUI
import AVFoundation

class MockTrack: TrackToken, AnyTrack {
    enum CodingKeys: String, CodingKey {
        case attributes
    }

	let _attributes: VolatileAttributes<TrackAttribute, TrackVersion> = .init()
	
	init(attributes: TypedDict<TrackAttribute>) {
		version = UUID().uuidString
		_attributes.update(.init(keys: Set(attributes.keys), attributes: attributes, state: .valid))
	}

    var icon: Image { Image(systemName: "questionmark") }
    
    var accentColor: Color { .primary}

    let uuid = UUID()
    
	var id: String { uuid.description }
	var origin: URL? { nil }
    
    func expand(_ context: Library) throws -> AnyTrack { self }

	func refreshVersion() {
		version = UUID().uuidString
	}

	@Published var version: TrackVersion

	func demand(_ demand: Set<TrackAttribute>) -> AnyCancellable {
		// The ones we don't have, we can never fulfill either
		_attributes.updateEmptyMissing(demand)
		return AnyCancellable { }
	}
	
	var attributes: AnyPublisher<TrackAttributes.Update, Never> {
		_attributes.updates.eraseToAnyPublisher()
	}

	func audioTrack(forDevice device: BranchingAudioDevice) throws -> AnyPublisher<AudioTrack, Error> {
		// TODO This doesn't work yet
		guard
			let device = device.av,
			let url = Bundle.main.url(forResource: "445632__djfroyd__c-major-scale", withExtension: "wav")
		else {
			throw UnsupportedAudioDeviceError()
		}
		
		return Future.tryOnQueue(.global(qos: .default)) { [url] in
			let file = try AVAudioFile(forReading: url)
			let singleDevice = try device.prepare(file)
			return AVAudioPlayerEmitter(singleDevice, file: file)
		}
			.eraseToAnyPublisher()
	}
    
	func supports(_ capability: TrackCapability) -> Bool {
		false
	}
	
    func invalidateCaches() { }
	
	func delete() throws {
		// Uuuhhhhh
	}
}
