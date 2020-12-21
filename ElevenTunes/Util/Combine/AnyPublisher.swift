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
    
    // Folds the result of the publisher until nil is returned.
    // This is useful for requests that warrant an immediate followup:
    // paginated(0)
    //    .fold { $0.page < $0.total ? paginated($0.page + 1) : nil  }
    //    .collect()
    func fold(limit: Int = 0, _ fun: @escaping (Output) -> AnyPublisher<Output, Failure>?) -> AnyPublisher<Output, Failure> {
        flatMap { value -> AnyPublisher<Output, Failure> in
            let justPublisher = Just(value).mapError { $0 as! Failure }.eraseToAnyPublisher()
            
            guard limit > 0, let publisher = fun(value) else {
                return justPublisher
            }
            return justPublisher.append(publisher.fold(limit: limit - 1, fun)).eraseToAnyPublisher()
        }.eraseToAnyPublisher()
    }
}

extension Publisher where Failure == Never {
    func assignWeak<Root: AnyObject>(to keyPath: ReferenceWritableKeyPath<Root, Output>, on root: Root) -> AnyCancellable {
       sink { [weak root] in
            root?[keyPath: keyPath] = $0
        }
    }
}
