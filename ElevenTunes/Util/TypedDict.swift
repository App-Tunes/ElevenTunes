//
//  TypedDict.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 18.12.20.
//

import Foundation

class AnyTypedKey {
}

class TypedKey<K: Hashable, V>: AnyTypedKey {
    let id: K
    
    init(_ id: K) {
        self.id = id
    }
}

class TypedDict<K: Hashable> {
    private var contents: [K: Any] = [:]
    
    init() { }
    
    init(_ dict: [K: Any]) {
        self.contents = dict
    }
    
    subscript<V>(_ key: TypedKey<K, V>) -> V? {
        get {
            return contents[key.id] as? V
        }
        
        set {
            contents[key.id] = newValue
        }
    }

}
