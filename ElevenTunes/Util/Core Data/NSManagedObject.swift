//
//  NSManagedObject.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 27.12.20.
//

import Foundation
import CoreData

extension NSManagedObject {
    func coreDataSet(_ newValue: Any?, forKey key: String) {
        willChangeValue(forKey: key)
        setPrimitiveValue(newValue, forKey: key)
        didChangeValue(forKey: key)
    }
    
    func coreDataGetValue<Type>(forKey key: String, type: Type.Type) -> Type? {
        willAccessValue(forKey: key)
        let value = primitiveValue(forKey: key) as? Type
        didAccessValue(forKey: key)
        return value
    }
}
