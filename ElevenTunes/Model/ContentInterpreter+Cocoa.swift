//
//  ContentInterpreter+Cocoa.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 14.02.21.
//

import Cocoa
import Combine

extension ContentInterpreter {
	func canInterpret(pasteboard info: NSPasteboard) -> Bool {
		info.canReadItem(withDataConformingToTypes: Self.types.map(\.identifier))
	}
	
	func interpret(pasteboard info: NSPasteboard) -> AnyPublisher<[Content], Error>? {
		var publishers: [AnyPublisher<Content, Error>] = []

		for type in Self.types {
			if info.canReadItem(withDataConformingToTypes: [type.identifier]) {
				publishers.append(
					info.loadData(forType: type)
						.mapError { _ in LoadError() }
						.tryFlatMap { item in try self.interpret(item, type: type) }
						.catch { error -> AnyPublisher<Content, Error> in
							if !(error is LoadError) {
								appLogger.error("Error reading content: \(error)")
							}
							return Empty<Content, Error>(completeImmediately: true)
								.eraseToAnyPublisher()
						}
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
