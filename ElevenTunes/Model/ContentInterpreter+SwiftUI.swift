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
    func interpret(drop info: DropInfo) -> AnyPublisher<[Content], Error>? {
        var publishers: [AnyPublisher<Content, Error>] = []

        for type in Self.types {
            for provider in info.itemProviders(for: [type]) {
                publishers.append(
                    provider.loadItem(forType: type)
                        .tryFlatMap { item in try self.interpret(item, type: type) }
                        .catch { error -> AnyPublisher<Content, Error> in
                            appLogger.error("Error reading track: \(error)")
                            return Empty<Content, Error>(completeImmediately: true).eraseToAnyPublisher()
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