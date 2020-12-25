//
//  Future.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 20.12.20.
//

import Foundation
import Combine

extension Future where Failure == Error {
    convenience init(_ callback: @escaping () throws -> Output) {
        self.init { promise in
            do {
                promise(.success(try callback()))
            }
            catch let error {
                promise(.failure(error))
            }
        }
    }
}

extension Future where Failure == Never {
    convenience init(_ callback: @escaping () -> Output) {
        self.init { promise in
            promise(.success(callback()))
        }
    }
}
