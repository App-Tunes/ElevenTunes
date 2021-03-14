//
//  TransientTrack.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 26.12.20.
//

import Foundation
import Combine
import SwiftUI

class MockTrack: TrackToken, AnyTrack {
    class MockError: Error {}
    
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
		AnyCancellable {}
	}
	
	var attributes: AnyPublisher<TrackAttributes.Update, Never> {
		_attributes.$update.eraseToAnyPublisher()
	}

    func emitter(context: PlayContext) -> AnyPublisher<AnyAudioEmitter, Error> {
        Fail(error: MockError()).eraseToAnyPublisher()
    }
    
    func invalidateCaches() { }
	
	func delete() throws {
		// Uuuhhhhh
	}
}
