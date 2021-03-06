//
//  ContentInterpreter+SwiftUI.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 24.12.20.
//

import Foundation
import SwiftUI
import Combine

extension ContentInterpreter {
    struct LoadError: Error {}
    
    func interpret(drop info: DropInfo) -> AnyPublisher<[Interpreted], Error>? {
        var publishers: [AnyPublisher<Interpreted, Error>] = []

        for type in self.types {
            for provider in info.itemProviders(for: [type]) {
                publishers.append(
                    provider.loadItem(forType: type)
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
