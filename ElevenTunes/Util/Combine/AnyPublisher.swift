//
//  AnyPublisher.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 20.12.20.
//

import Foundation
import Combine

extension AnyPublisher {
    func onMain() -> Publishers.ReceiveOn<AnyPublisher<Output, Failure>, RunLoop> {
        return receive(on: RunLoop.main)
    }
}

extension Publisher where Failure == Never {
    func assignWeak<Root: AnyObject>(to keyPath: ReferenceWritableKeyPath<Root, Output>, on root: Root) -> AnyCancellable {
       sink { [weak root] in
            root?[keyPath: keyPath] = $0
        }
    }
}
