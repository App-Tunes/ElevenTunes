//
//  AppLog.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 25.12.20.
//

import Foundation
import Logging
import Combine

let appLogger = Logger(label: "ElevenTunes")

func appLogErrors(_ completion: Subscribers.Completion<Error>) {
    switch completion {
    case .failure(let error):
        appLogger.error("Error: \(error)")
    default:
        return
    }
}

extension NSManagedObjectContext {
	func trySaveOnChildTask(concurrencyType: NSManagedObjectContextConcurrencyType = .privateQueueConcurrencyType, _ task: @escaping (NSManagedObjectContext) throws -> Void) {
		let context = self.child(concurrencyType: concurrencyType)

		// TODO Need to wait for now because otherwise it won't get called (context dealloc?)
		context.performAndWait {
			do {
				try task(context)
				try context.save()
			}
			catch let error {
				appLogger.error("Error on commit: \(error)")
			}
		}
	}
}
