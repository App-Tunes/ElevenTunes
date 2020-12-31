//
//  TypedDict.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 18.12.20.
//

import Foundation

protocol TypedKey: Hashable {
    associatedtype Value
}

public class TypedDict<K: AnyObject & Hashable> {
    private var contents: [K: Any] = [:]
    
    init() { }
    
    init(_ dict: [K: Any?]) {
        self.contents = dict.compactMapValues { $0 }
    }
    
    var isEmpty: Bool { contents.isEmpty }
    
    func merge(_ dict: TypedDict<K>) {
        for (key, value) in dict.contents {
            contents[key] = value
        }
    }
    
    // Type hinting will have to wait for
    // https://github.com/apple/swift/blob/main/docs/GenericsManifesto.md#generalized-supertype-constraints
    // to be implemented :(
    subscript<TK>(_ key: TK) -> TK.Value? where TK: TypedKey {
        get {
            let k = key as! K
            return contents[k] as? TK.Value
        }
        
        set {
            let k = key as! K
            contents[k] = newValue
        }
    }
}

extension TypedDict: CustomStringConvertible {
    public var description: String { contents.description }
}
