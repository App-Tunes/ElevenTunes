//
//  SetRelation.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 09.01.21.
//

import Foundation

class SetRelation<Source: Hashable, Dest: Hashable>: ExpressibleByDictionaryLiteral {
	let graph: [Dest: Set<Source>]
	
	init(_ graph: [Dest: Set<Source>]) {
		self.graph = graph
	}

	required init(dictionaryLiteral elements: (Dest, Set<Source>)...) {
		self.graph = Dictionary(uniqueKeysWithValues: elements)
	}
	
	subscript(dest: Dest) -> Set<Source>? { graph[dest] }

	func explode(_ source: Set<Source>, with dest: Set<Dest>? = nil) -> Set<Source> {
		let groups: [Set<Source>] = dest.map { $0.map { graph[$0] ?? [] } } ?? Array(graph.values)
		return groups.reduce(into: source) {
			if !source.isDisjoint(with: $1) { $0 = source.union($1) }
		}
	}
	
	func any(_ source: Set<Source>) -> Set<Dest> {
		Set(graph.filter { !$0.value.isDisjoint(with: source) }
			.map(\.key))
	}
	
	func translate(_ source: Set<Source>) -> (Set<Dest>, unknown: Set<Source>) {
		let known = any(source)
		return (known, unknown: source.subtracting(Set(known.flatMap { graph[$0]! })))
	}
}
