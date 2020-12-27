//
//  CodableTransformer.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 26.12.20.
//

import Foundation

class TypedJSONCodableTransformer<Key: Hashable & Codable, Wrapper: TypedCodable<Key>>: ValueTransformer {
    override class func transformedValueClass() -> AnyClass { NSData.self }
    override class func allowsReverseTransformation() -> Bool { true }
            
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()
    
    override func transformedValue(_ value: Any?) -> Any? {
        guard let value = value else { return nil }
        guard let codable = value as? Codable else {
            appLogger.error("Tried encoding uncodable object \(value)")
            return nil
        }
        guard let wrapper = Wrapper(codable) else {
            appLogger.error("Tried encoding unregistered object \(value)")
            return nil
        }
        return try? encode(wrapper)
    }
    
    func encode(_ object: Wrapper) throws -> Data {
        try encoder.encode(object)
    }

    override func reverseTransformedValue(_ value: Any?) -> Any? {
        guard let data = value as? NSData else {
            return nil
        }
        return try? decode(data as Data).object
    }
    
    func decode(_ data: Data) throws -> Wrapper {
        try decoder.decode(Wrapper.self, from: data)
    }
}
