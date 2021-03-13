//
//  NSManagedObjectContext.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 27.12.20.
//

import Foundation
import CoreData

extension NSManagedObjectContext {
	enum InterpretationError: Error {
		case wrongType
	}
	
    func child(concurrencyType: NSManagedObjectContextConcurrencyType) -> NSManagedObjectContext {
        let child = NSManagedObjectContext(concurrencyType: concurrencyType)
        child.parent = self
        return child
    }
    
    func performChildTask(concurrencyType: NSManagedObjectContextConcurrencyType, wait: Bool = false, _ task: @escaping (NSManagedObjectContext) -> Swift.Void) {
        let context = self.child(concurrencyType: concurrencyType)
        (wait ? context.performAndWait : context.perform) {
            task(context)
        }
    }

    func translate<T: NSManagedObject>(_ object: T) -> T? {
        self.object(with: object.objectID) as? T
    }
    
    func read<T>(uri: URL?, as: T.Type) throws -> T {
        try (uri.flatMap { persistentStoreCoordinator?.managedObjectID(forURIRepresentation: $0) }
			.flatMap { try existingObject(with: $0) } as? T).unwrap(orThrow: InterpretationError.wrongType)
    }
}
