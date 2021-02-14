//
//  VolatileAttributes.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 09.01.21.
//

import Foundation
import Combine

public enum VolatileState<Version: Hashable>: Equatable {
	case valid
	/// The state has not been fetched yet. A load might be in process,
	/// or has yet to be scheduled.
	/// If a value is provided, it is a guess or a cache.
	case missing
	/// An attempt at a fetch was made, but failed. A retry is recommended.
	/// If a value is provided, it is a guess or a cache.
	case error(Error)
	
	var isKnown: Bool {
		if case .missing = self {
			return false
		}
		return true
	}

	static func combine(_ lhs: VolatileState?, _ rhs: VolatileState?) -> VolatileState? {
		// Weirdest code ever lol
		if case .error = lhs { return lhs }
		if case .error = rhs { return rhs }
		if case .missing = lhs { return .missing }
		if case .missing = rhs { return .missing }
		// Both are versioned. Collapse
		return .valid
	}
	
	public static func == (lhs: VolatileState, rhs: VolatileState) -> Bool {
		if case .error(let lerror) = lhs, case .error(let rerror) = rhs {
			// Eh, good enough.
			return ObjectIdentifier(lerror as AnyObject) == ObjectIdentifier(rerror as AnyObject)
		}
		if case .valid = lhs, case .valid = rhs { return true }
		if case .missing = lhs, case .missing = rhs { return true }
		return false
	}
}

public struct VolatileSnapshot<Value, Version: Hashable> {
	public typealias State = VolatileState<Version>
	
	var value: Value?
	var state: State
	
	init(_ value: Value?, state: State) {
		self.value = value
		self.state = state
	}
	
	func map<T>(_ fun: (Value) -> T) -> VolatileSnapshot<T, Version> {
		.init(value.map(fun), state: state)
	}

	static func missing(_ value: Value? = nil) -> VolatileSnapshot {
		.init(value, state: .missing)
	}
}

extension VolatileSnapshot: Equatable where Value: Equatable { }

public class VolatileAttributes<Key: AnyObject & Hashable, Version: Hashable> {
	public typealias Update = (Snapshot, change: Set<Key>)
	
	private let lock = NSLock()

	@Published private(set) var snapshot: Snapshot = .init()
	@Published private(set) var update: Update = (.init(), [])
	
	var knownKeys: Set<Key> {
		lock.perform { snapshot.knownKeys }
	}

	func update(_ group: GroupSnapshot) {
		update(Snapshot(group: group))
	}
	
	func updateEmpty(_ keys: Set<Key>, state: State) {
		update(Snapshot(group: GroupSnapshot(keys: keys, attributes: .init(), state: state)))
	}

	func update(_ snapshot: Snapshot) {
		guard !snapshot.isEmpty else { return }

		let fullSnapshot = lock.perform { () -> Snapshot in
			self.snapshot = self.snapshot.merging(update: snapshot)

			return self.snapshot
		}
		
		self.update = (fullSnapshot, change: Set(snapshot.states.keys))
	}
	
	func invalidate() {
		lock.perform {
			snapshot = snapshot.invalidated()
			update = (snapshot, Set(snapshot.states.keys))
		}
	}
}

extension VolatileAttributes {
	public typealias State = VolatileState<Version>
	public typealias ValueSnapshot<Value> = VolatileSnapshot<Value, Version>

	public struct GroupSnapshot {
		let keys: Set<Key>
		let attributes: TypedDict<Key>
		let state: State
		
		init(keys: Set<Key>, attributes: TypedDict<Key>, state: State) {
			self.keys = keys
			self.attributes = attributes
			self.state = state
		}
		
		public static func unsafe(_ attributes: [Key: Any?], state: State) -> GroupSnapshot {
			GroupSnapshot(keys: Set(attributes.keys), attributes: .unsafe(attributes), state: state)
		}
		
		func explode() -> Snapshot { Snapshot(group: self) }
	}
	
	public class Snapshot {
		let attributes: TypedDict<Key>
		let states: [Key: State]
		
		init() {
			attributes = .init()
			states = [:]
		}
		
		init(_ attributes: TypedDict<Key>, states: [Key: State]) {
			self.attributes = attributes
			self.states = states
		}
		
		convenience init(group: GroupSnapshot) {
			self.init(group.attributes, states: Dictionary(uniqueKeysWithValues: group.keys.map {
				($0, group.state)
			}))
		}
		
		var isEmpty: Bool { attributes.isEmpty && states.isEmpty }
		
		var keys: Dictionary<Key, State>.Keys { states.keys }
		
		var knownKeys: Set<Key> {
			Set(states.filter { $0.value != .missing }.map { $0.key })
		}
		
		func invalidated() -> Snapshot {
			Snapshot(attributes, states: states.mapValues { _ in State.missing })
		}
		
		// Type hinting see TypedDict :(
		public subscript<TK>(_ key: TK) -> ValueSnapshot<TK.Value> where TK: TypedKey {
			ValueSnapshot(attributes[key], state: states[key as! Key] ?? .missing)
		}
		
		public func extract<C>(_ keys: C) -> GroupSnapshot where C: Collection, C.Element == Key {
			let attributes = self.attributes.filter(keys.contains)
			let state: State? = keys
				.map { states[$0] ?? .missing }
				.reduce(into: nil) { $0 = $1 }
			
			return GroupSnapshot(keys: Set(keys), attributes: attributes, state: state ?? .missing)
		}
		
		/// Merges the snapshots according to 'update' logic
		public func merging(update: Snapshot) -> Snapshot {
			// Merging by "update" logic just means we're the cache lol
			return update.merging(cache: self)
		}
		
		/// Merges the snapshots according to 'cache' logic
		public func merging(cache: Snapshot) -> Snapshot {
			let notMissing = attributes.filter { (states[$0] ?? .missing).isKnown }
			let justMissing = attributes.filter { !(states[$0] ?? .missing).isKnown }

			return Snapshot(
				// Merge attributes - ours trumps cache. If ours are marked as 'missing',
				// cache trumps ours since ours is just a guess.
				notMissing
					.merging(cache.attributes, stronger: .left)
					.merging(justMissing, stronger: .left),
				// Merge states - ours trumps cache if it's known.
				states: states
					.filter { $0.value.isKnown }
					.merging(cache.states) { (l, r) in l }
			)
		}
		
		public func filter(_ isIncluded: (Key) -> Bool) -> Snapshot {
			Snapshot(attributes.filter(isIncluded), states: states.filter { isIncluded($0.key) })
		}
	}
}

extension Publisher {
//	func publisher(_ attributes: Set<Key>) -> AnyPublisher<Snapshot, Never> {
//		// Always push the initial value through, and from then on only if relevant
//		Just(snapshot.0).append(
//			$snapshot.dropFirst().compactMap { (values, change) in
//				if change.isDisjoint(with: attributes) {
//					return nil
//				}
//
//				return values
//			}
//		).eraseToAnyPublisher()
//	}

	func filtered<Key, Version>(toChanges keys: Set<Key>) -> AnyPublisher<VolatileAttributes<Key, Version>.Snapshot, Failure> where Output == VolatileAttributes<Key, Version>.Update {
		var isFirst = true
		
		return compactMap { (values, change) -> VolatileAttributes<Key, Version>.Snapshot? in
			if !isFirst, change.isDisjoint(with: keys) {
				return nil
			}
			
			isFirst = false
			return values
		}
			.eraseToAnyPublisher()
	}
	
	func filtered<Key, TK: TypedKey, Version>(toJust key: TK) -> AnyPublisher<VolatileSnapshot<TK.Value, Version>, Failure> where Output == VolatileAttributes<Key, Version>.Update {
		filtered(toChanges: [key as! Key])
			.map { $0[key] }
			.eraseToAnyPublisher()
	}
}
