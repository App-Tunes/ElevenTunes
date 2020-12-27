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
    
    func interpret(drop info: DropInfo) -> AnyPublisher<[Content], Error>? {
        var publishers: [AnyPublisher<Content, Error>] = []

        for type in Self.types {
            for provider in info.itemProviders(for: [type]) {
                publishers.append(
                    provider.loadItem(forType: type)
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
