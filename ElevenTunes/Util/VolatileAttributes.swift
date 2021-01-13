//
//  VolatileAttributes.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 09.01.21.
//

import Foundation
import Combine

public enum VolatileState<Version: Hashable>: Equatable {
	/// The state is valid, and final for the version. If nil, the state is final for all versions.
	case version(Version?)
	/// The state has not been fetched yet. A load might be in process,
	/// or has yet to be scheduled.
	/// If a value is provided, it is a guess or a cache.
	case missing
	/// An attempt at a fetch was made, but failed. A retry is recommended.
	/// If a value is provided, it is a guess or a cache.
	case error(Error)
	
	var isVersioned: Bool {
		if case .version = self {
			return true
		}
		return false
	}
	
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
		if case .version(let lversion) = lhs, case .version(let rversion) = rhs {
			if let lversion = lversion, let rversion = rversion {
				// Missing because two different versions means one is out of date
				return lversion == rversion ? lhs : .missing
			}
			return .version(lversion ?? rversion)
		}
		// Cannot reach here
		fatalError()
	}
	
	public static func == (lhs: VolatileState, rhs: VolatileState) -> Bool {
		if case .version(let lversion) = lhs, case .version(let rversion) = rhs {
			return lversion == rversion
		}
		if case .error(let lerror) = lhs, case .error(let rerror) = rhs {
			// Eh, good enough.
			return ObjectIdentifier(lerror as AnyObject) == ObjectIdentifier(rerror as AnyObject)
		}
		if case .missing = lhs, case .missing = rhs { return true }
		return false
	}
}

public struct VolatileSnapshot<Value, Version: Hashable> {
	public typealias State = VolatileState<Version>
	
	var value: Value
	var state: State
	
	init(_ value: Value, state: State) {
		self.value = value
		self.state = state
	}
	
	static func missing(_ value: Value) -> VolatileSnapshot {
		.init(value, state: .missing)
	}

	static func missing<V>() -> VolatileSnapshot where Value == Optional<V> {
		.init(nil, state: .missing)
	}
}

extension VolatileSnapshot: Equatable where Value: Equatable { }

public class VolatileAttributes<Key: AnyObject & Hashable, Version: Hashable> {
	public typealias Update = (Snapshot, change: Set<Key>)
	
	private let lock = NSLock()

	private var attributes: TypedDict<Key> = .init()
	private var states: [Key: State] = [:]
	
	@Published private(set) var snapshot: Update = (.init(), [])
	
	var knownKeys: Set<Key> {
		lock.perform { Set(states.filter { $0.value != .missing }.map { $0.key }) }
	}
	
	func update(_ attributes: TypedDict<Key>, state: State) {
		guard !attributes.isEmpty else { return }

		let snapshot = lock.perform { () -> Snapshot in
			self.attributes.merge(attributes, stronger: .right)
			attributes.keys.forEach { states[$0] = state }
			
			return Snapshot(self.attributes, states: states)
		}
		
		self.snapshot = (snapshot, change: Set(attributes.keys))
	}
	
	func updateEmpty(_ attributes: Set<Key>, state: State) {
		guard !attributes.isEmpty else { return }
		
		let snapshot = lock.perform { () -> Snapshot in
			self.attributes = self.attributes.filter { !attributes.contains($0) }
			attributes.forEach { states[$0] = state }
			
			return Snapshot(self.attributes, states: states)
		}
		
		self.snapshot = (snapshot, change: attributes)
	}
	
	func update(_ snapshot: Snapshot, change: Set<Key>) {
		guard !snapshot.isEmpty else { return }

		let fullSnapshot = lock.perform { () -> Snapshot in
			self.attributes.merge(snapshot.attributes, stronger: .right)
			states.merge(snapshot.states) { $1 }

			return Snapshot(self.attributes, states: states)
		}
		
		self.snapshot = (fullSnapshot, change: change)
	}
	
	func invalidate() {
		lock.perform {
			states = states.mapValues { State.combine($0, .missing)! }
		}
	}
}

extension VolatileAttributes {
	public typealias State = VolatileState<Version>
	public typealias ValueSnapshot<Value> = VolatileSnapshot<Value, Version>
	public typealias ValueGroupSnapshot = ValueSnapshot<TypedDict<Key>>
	
	public class Snapshot {
		private(set) var attributes: TypedDict<Key>
		private(set) var states: [Key: State]
		
		init(_ attributes: TypedDict<Key>, states: [Key: State]) {
			self.attributes = attributes
			self.states = states
		}
		
		init() {
			attributes = .init()
			states = [:]
		}
		
		static func empty() -> Snapshot {
			.init(.init(), states: [:])
		}
		
		var isEmpty: Bool { attributes.isEmpty && states.isEmpty }
		
		// Type hinting see TypedDict :(
		public subscript<TK>(_ key: TK) -> ValueSnapshot<TK.Value?> where TK: TypedKey {
			ValueSnapshot(attributes[key], state: states[key as! Key] ?? .missing)
		}
		
		public func extract<C>(_ keys: C) -> ValueGroupSnapshot where C: Collection, C.Element == Key {
			let attributes = self.attributes.filter(keys.contains)
			let state: State? = keys
				.map { states[$0] ?? .missing }
				.reduce(into: nil) { $0 = $1 }
			
			return ValueSnapshot(attributes, state: state ?? .missing)
		}
		
		/// Merges the snapshots according to 'cache' logic
		public func merging(cache: Snapshot) -> Snapshot {
			let notMissing = attributes.filter { (states[$0] ?? .missing).isKnown }
			let justMissing = attributes.filter { !(states[$0] ?? .missing).isKnown }

			let snapshot = Snapshot(
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
			return snapshot
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
	
	func filtered<Key, TK: TypedKey, Version>(toJust key: TK) -> AnyPublisher<VolatileSnapshot<TK.Value?, Version>, Failure> where Output == VolatileAttributes<Key, Version>.Update {
		filtered(toChanges: [key as! Key])
			.map { $0[key] }
			.eraseToAnyPublisher()
	}
}
