//
//  NSItemProvider.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 20.12.20.
//

import Foundation
import Combine
import UniformTypeIdentifiers

extension NSItemProvider {
    class UnknownError: Error { }
    
    func loadItem(forType type: UTType, options: [AnyHashable: Any]? = nil) -> Future<NSSecureCoding, Error> {
        return Future { promise in
            self.loadItem(forTypeIdentifier: type.identifier, options: options) { item, error in
                guard let item = item else {
                    promise(.failure(error ?? UnknownError()))
                    return
                }
                
                promise(.success(item))
            }
        }
    }
}
