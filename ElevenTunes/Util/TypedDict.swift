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
    
    init(_ dict: [K: Any]) {
        self.contents = dict
    }
    
    func merge(_ dict: TypedDict<K>) {
        // TODO
//        contents += dict.contents
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
