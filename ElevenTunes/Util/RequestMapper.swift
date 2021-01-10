//
//  RequestMapper.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 09.01.21.
//

import Foundation
import Combine

protocol RequestMapperDelegate: AnyObject {
	associatedtype Request: Hashable
	
	func onDemand(_ requests: Set<Request>)
}

class RequestMapper<Attribute: AnyObject & Hashable, Version: Hashable, Delegate: RequestMapperDelegate> {
	let demand = KeyedDemand<Attribute>()
	let attributes = VolatileAttributes<Attribute, Version>()
	let relation: SetRelation<Attribute, Delegate.Request>
	
	var cancellables: Set<AnyCancellable> = []
	
	var delegate: Delegate?
	
	init(relation: SetRelation<Attribute, Delegate.Request>) {
		self.relation = relation
		
		let attributes = self.attributes
		demand.$demand
			.map { Set($0.keys) }
			.map { $0.subtracting(attributes.knownKeys) }
			.removeDuplicates()
			.map(relation.translate)
			.sink { [weak self] in
				// Register the ones we don't know as 'nil, but final'
				// TODO The version must match - we need to somehow provide it
//				attributes.updateEmpty($0.unknown, state: .version(""))
				// Ask delegate to compute the rest
				self?.delegate?.onDemand($0.0)
			}
			.store(in: &cancellables)
	}
}
