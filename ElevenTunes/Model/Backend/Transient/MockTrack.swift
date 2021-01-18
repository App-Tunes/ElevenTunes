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
		super.init()
		_attributes.update(.init(keys: Set(attributes.keys), attributes: attributes, state: .version(version)))
	}

    public required init(from decoder: Decoder) throws {
        fatalError()
//        let container = try decoder.container(keyedBy: CodingKeys.self)
//        // TODO
//        try super.init(from: decoder)
    }

    public override func encode(to encoder: Encoder) throws {
        fatalError()
//        var container = encoder.container(keyedBy: CodingKeys.self)
//        // TODO
//        try super.encode(to: encoder)
    }
    
    var asToken: TrackToken { self }
    
    var icon: Image { Image(systemName: "questionmark") }
    
    var accentColor: Color { .primary}

    let uuid = UUID()
    override var id: String { uuid.description }
    
    override func expand(_ context: Library) -> AnyTrack { self }

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
}
