//
//  NSManagedObjectContext.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 27.12.20.
//

import Foundation
import CoreData

extension NSManagedObjectContext {
    func child(concurrencyType: NSManagedObjectContextConcurrencyType) -> NSManagedObjectContext {
        let child = NSManagedObjectContext(concurrencyType: concurrencyType)
        child.parent = self
        return child
    }
    
    func translate<T: NSManagedObject>(_ object: T) -> T? {
        self.object(with: object.objectID) as? T
    }
}
