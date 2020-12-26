//
//  CodableRegistry.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 26.12.20.
//

import Foundation

class CodableRegistry<Key: Codable & Hashable> {
    enum CodingError: Error {
        case unknownKey(key: Key)
        case unknownType(type: Any.Type)
    }
    
    private(set) var typeForKey: [Key: Codable.Type] = [:]
    private(set) var keyForType: [ObjectIdentifier: Key] = [:]

    func register<A: Codable>(_ type: A.Type, for key: Key) -> CodableRegistry {
        typeForKey[key] = type
        keyForType[ObjectIdentifier(type)] = key
        return self
    }
    
    subscript(key key: Key) -> Codable.Type? { typeForKey[key] }
    subscript(type type: Any.Type) -> Key? { keyForType[ObjectIdentifier(type)] }
    subscript(typeOf object: Any) -> Key? { self[type: Swift.type(of: object)] }
    
    func type(_ key: Key) throws -> Codable.Type {
        guard let type = typeForKey[key] else {
            throw CodingError.unknownKey(key: key)
        }
        return type
    }

    func key(_ type: Any) throws -> Key {
        let type = Swift.type(of: type)
        guard let key = keyForType[ObjectIdentifier(type)] else {
            throw CodingError.unknownType(type: type)
        }
        return key
    }
}

class TypedCodable<Key: Codable & Hashable>: Codable {
    enum CodingKeys: String, CodingKey {
      case type, data
    }
    
    class var registry: CodableRegistry<Key> { fatalError("TypedCodable needs to be subclassed") }
    
    let object: Codable
        
    required init?(_ object: Codable) {
        guard Self.registry[typeOf: object] != nil else {
            return nil
        }
        
        self.object = object
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try Self.registry.type(container.decode(Key.self, forKey: .type))
        object = try type.init(from: container.superDecoder(forKey: .data))
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        let key = try Self.registry.key(object)
        try container.encode(key, forKey: .type)
        try object.encode(to: container.superEncoder(forKey: .data))
    }
}
