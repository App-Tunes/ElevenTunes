//
//  CodableTransformer.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 26.12.20.
//

import Foundation

class CodableTransformer: ValueTransformer {
    override class func transformedValueClass() -> AnyClass {
        NSData.self
    }

    override class func allowsReverseTransformation() -> Bool {
        true
    }
    
    class var classes: [AnyClass] { [] }
    
    override func transformedValue(_ value: Any?) -> Any? {
        guard let data = value as? Data else {
            return nil
        }
        
        return try? NSKeyedUnarchiver.unarchivedObject(ofClasses: Self.classes, from: data)
    }

    override func reverseTransformedValue(_ value: Any?) -> Any? {
        guard let value = value else { return nil }
        return try? NSKeyedArchiver.archivedData(withRootObject: value, requiringSecureCoding: true)
    }
}
