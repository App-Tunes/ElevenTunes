//
//  BranchingTrack.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 25.01.21.
//

import Foundation
import Combine
import SwiftUI

enum PartialTrackMask {
	case full
	case none
}

public class BranchingTrack: AnyTrack {
	private(set) var cache: DBTrack
	
	let primary: AnyTrack
	let secondary: [AnyTrack]
	
	init(cache: DBTrack, primary: AnyTrack, secondary: [AnyTrack]) {
		self.cache = cache
		self.primary = primary
		self.secondary = secondary
	}
	
	public var id: String { primary.id }
	
	public var origin: URL? { primary.origin }
	
	public var icon: Image { primary.icon }
	
	public var accentColor: Color { primary.accentColor }
	
	public func invalidateCaches() { primary.invalidateCaches() }

	public var attributes: AnyPublisher<TrackAttributes.Update, Never> {
		primary.attributes
	}
	
	public func demand(_ demand: Set<TrackAttribute>) -> AnyCancellable {
		primary.demand(demand)
	}

	public func emitter(context: PlayContext) -> AnyPublisher<AnyAudioEmitter, Error> {
		primary.emitter(context: context)
	}
}

extension BranchingTrack: Hashable {
	public static func == (lhs: BranchingTrack, rhs: BranchingTrack) -> Bool {
		lhs.id == rhs.id
	}
	
	public func hash(into hasher: inout Hasher) {
		hasher.combine(id)
	}
}

extension AnyTrack {
	var primary: AnyTrack {
		(self as? BranchingTrack)?.primary ?? self
	}
}
