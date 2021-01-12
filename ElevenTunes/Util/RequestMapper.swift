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
	associatedtype Snapshot
	
	func onDemand(_ request: Request) -> AnyPublisher<Snapshot, Error>
}

class RequestMapper<Attribute: AnyObject & Hashable, Version: Hashable, Delegate: RequestMapperDelegate> where Delegate.Snapshot == VolatileAttributes<Attribute, Version>.ValueGroupSnapshot {
	enum DesignError: Error {
		case noDelegate
	}
	
	let demand = KeyedDemand<Attribute>()
	let attributes = VolatileAttributes<Attribute, Version>()
	let relation: SetRelation<Attribute, Delegate.Request>
	
	var requestFeatureSet = FeatureSet<Delegate.Request, Set<Delegate.Request>>()
	
	var cancellables: Set<AnyCancellable> = []
	
	var delegate: Delegate?
	
	init(relation: SetRelation<Attribute, Delegate.Request>) {
		self.relation = relation

		let attributes = self.attributes
		demand.$demand
			.map { Set($0.keys) }
			// Subtract attributes we already know; in rare cases
			// this may avoid generating a request
			.map { $0.subtracting(attributes.knownKeys) }
			.removeDuplicates()
			.map(relation.translate)
			.sink { [weak self] (requests, unknown) in
				guard let self = self else { return }
				
				// Register unknown as error (don't know how to provide...)
				// TODO Maybe it would be better to map this elsehow, we'll see
				attributes.updateEmpty(unknown, state: .version(nil))
				
				// Ask delegate to compute the rest
				requests.forEach(self.demandRequest)
			}
			.store(in: &cancellables)
	}
	
	func demandRequest(_ request: Delegate.Request) {
		let attributes = self.attributes
		
		// Only ask to fulfill the request if we don't do it already
		requestFeatureSet.promise([request]) { promise in
			let promisedAttributes = relation[request]!

			guard let delegate = delegate else {
				appLogger.critical("Request '\(request)' of \(Delegate.self) demanded without a delegate registered!")
				attributes.updateEmpty(promisedAttributes, state: .error(DesignError.noDelegate))
				return
			}
			
			delegate
				.onDemand(request)
				.onMain()
				.fulfillingAny([request], of: promise)
				.sink { result in
					switch result {
					case .failure(let error):
						attributes.updateEmpty(promisedAttributes, state: .error(error))
					case .success(let snapshot):
						// snapshot may provide more if unexpectedly there was more,
						// or less if the version doesn't have an attribute
						let allKeys = promisedAttributes.union(snapshot.value.keys)
						let fullSnapshot = VolatileAttributes<Attribute, Version>.Snapshot(snapshot.value, states: Dictionary(uniqueKeysWithValues: allKeys.map { ($0, snapshot.state) }))
						
						attributes.update(fullSnapshot, change: allKeys)
					}
				}
				.store(in: &cancellables)
		}
	}
}
