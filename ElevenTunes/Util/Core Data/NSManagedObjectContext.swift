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
    
	func performAsyncChildTask(concurrencyType: NSManagedObjectContextConcurrencyType, _ task: @escaping (NSManagedObjectContext) -> Swift.Void) {
		let context = self.child(concurrencyType: concurrencyType)
		context.perform {
			task(context)
		}
	}

	func performChildTask<R>(concurrencyType: NSManagedObjectContextConcurrencyType, _ task: @escaping (NSManagedObjectContext) -> R) -> R {
		let context = self.child(concurrencyType: concurrencyType)
		var r: R? = nil
		context.performAndWait {
			r = task(context)
		}
		return r!
	}
	
	func withChildTaskTranslate<T: NSManagedObject, R>(_ object: T?, concurrencyType: NSManagedObjectContextConcurrencyType = .privateQueueConcurrencyType, _ task: @escaping (T) -> R?) -> R? {
		guard let object = object else { return nil }
		return performChildTask(concurrencyType: concurrencyType) { context in
			context.translate(object).flatMap { task($0) }
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
