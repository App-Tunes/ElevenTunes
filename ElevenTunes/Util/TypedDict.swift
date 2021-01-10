//
//  TypedDict.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 18.12.20.
//

import Foundation

public protocol TypedKey: Hashable {
    associatedtype Value
}

public struct TypedDict<K: AnyObject & Hashable> {
	public enum Side {
		case left, right
	}
	
    private(set) var contents: [K: Any] = [:]
    
    init() { }
    
    init(_ dict: [K: Any?]) {
        self.contents = dict.compactMapValues { $0 }
    }
	
	public var count: Int { contents.count }
	
	var keys: Dictionary<K, Any>.Keys { contents.keys }
    
	public var isEmpty: Bool { contents.isEmpty }
    
	public mutating func merge(_ dict: TypedDict<K>, stronger side: Side) {
		contents.merge(dict.contents) { side == .left ? $0 : $1 }
	}
		
	public func merging(_ dict: TypedDict<K>, stronger side: Side) -> TypedDict {
		TypedDict(contents.merging(dict.contents) { side == .left ? $0 : $1 })
	}
		
    // Type hinting will have to wait for
    // https://github.com/apple/swift/blob/main/docs/GenericsManifesto.md#generalized-supertype-constraints
    // to be implemented :(
	public subscript<TK>(_ key: TK) -> TK.Value? where TK: TypedKey {
		get {
			let k = key as! K
			return contents[k] as? TK.Value
		}
		
		set {
			let k = key as! K
			contents[k] = newValue
		}
	}

	public subscript(unsafe key: K) -> Any? {
		get { contents[key] }
		
		set { contents[key] = newValue }
	}

	public func filter(_ isIncluded: (K) throws -> Bool) rethrows -> TypedDict {
		TypedDict(try contents.filter { try isIncluded($0.key) })
	}
}

extension TypedDict: CustomStringConvertible {
    public var description: String { contents.description }
}
