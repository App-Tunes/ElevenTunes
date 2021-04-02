//
//  Future.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 20.12.20.
//

import Foundation
import Combine

extension Future where Failure == Error {
    static func trySync(_ callback: @escaping () throws -> Output) -> Future {
        Future { promise in
            do {
                promise(.success(try callback()))
            }
            catch let error {
                promise(.failure(error))
            }
        }
    }
	
	static func tryOnQueue(_ queue: DispatchQueue, callback: @escaping () throws -> Output) -> Future {
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
    static func sync(_ callback: @escaping () -> Output) -> Future {
        self.init { promise in
            promise(.success(callback()))
        }
    }
	
	static func onQueue(_ queue: DispatchQueue, callback: @escaping () -> Output) -> Future {
		Future { promise in
			queue.async {
				promise(.success(callback()))
			}
		}
	}
}
