//
//  Future.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 20.12.20.
//

import Foundation
import Combine

extension Future where Failure == Error {
	/// TODO Deprecated. Use Just() for local, or onQueue for background tasks.
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
	
	static func onQueue(_ queue: DispatchQueue, callback: @escaping () throws -> Output) -> Future {
		Future { promise in
			queue.async {
				do {
					promise(.success(try callback()))
				}
				catch let error {
					promise(.failure(error))
				}
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
