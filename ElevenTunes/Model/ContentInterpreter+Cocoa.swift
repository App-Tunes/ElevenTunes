//
//  ContentInterpreter+Cocoa.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 14.02.21.
//

import Cocoa
import Combine

extension ContentInterpreter {
	func interpret(pasteboard info: NSPasteboard) -> AnyPublisher<[Interpreted], Error>? {
		var publishers: [AnyPublisher<Interpreted, Error>] = []

		for type in self.types {
			if info.canReadItem(withDataConformingToTypes: [type.identifier]) {
				publishers.append(
					info.loadData(forType: type)
						.mapError { _ in LoadError() }
						.tryCompactMap { item in try self.interpret(item, type: type) }
						.eraseToAnyPublisher()
					)
			}
		}
		
		guard !publishers.isEmpty else {
			return nil
		}
		
		return Publishers.MergeMany(publishers)
			.collect()
			.eraseToAnyPublisher()
	}
}
