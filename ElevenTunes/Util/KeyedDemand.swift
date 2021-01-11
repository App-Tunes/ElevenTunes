//
//  TypedDemand.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 09.01.21.
//

import Foundation
import Combine

public class KeyedDemand<Feature: Hashable> {
	struct Demand: Identifiable, Hashable, Cancellable {
		weak var parent: KeyedDemand?
		let id = UUID()
		var features: Set<Feature>
		
		static func == (lhs: KeyedDemand<Feature>.Demand, rhs: KeyedDemand<Feature>.Demand) -> Bool {
			lhs.id == rhs.id
		}
		
		func hash(into hasher: inout Hasher) {
			hasher.combine(id)
		}

		func cancel() {
			parent?.remove(self)
		}
	}
	
	private let lock = NSLock()
	
	private(set) var demands: Set<Demand> = []
	@Published private(set) var demand: [Feature: Int] = [:]
	
	func add(_ features: Set<Feature>) -> AnyCancellable {
		let demand = Demand(parent: self, features: features)
		lock.perform {
			self.demands.insert(demand)
			updateDemand(demand.features, add: 1)
		}
		return AnyCancellable(demand)
	}
	
	func remove(_ demand: Demand) {
		lock.perform {
			guard self.demands.remove(demand) != nil else {
				return
			}
			updateDemand(demand.features, add: -1)
		}
	}
	
	private func updateDemand(_ features: Set<Feature>, add value: Int) {
		var updatedDemand = self.demand

		for feature in features {
			var currentDemand = updatedDemand[feature, default: 0]
			currentDemand += value
			
			if currentDemand < 0 {
				appLogger.error("Fucked up demand calculation")
			}
			if currentDemand <= 0 {
				updatedDemand.removeValue(forKey: feature)
			}
			else {
				updatedDemand[feature] = currentDemand
			}
		}
		
		self.demand = updatedDemand
	}
}
