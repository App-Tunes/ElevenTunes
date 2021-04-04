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
	@discardableResult
	func trySaveOnChildTask(concurrencyType: NSManagedObjectContextConcurrencyType = .privateQueueConcurrencyType, _ task: @escaping (NSManagedObjectContext) throws -> Void) -> Bool {
		do {
			try saveOnChildTask(concurrencyType: concurrencyType, task)
			return true
		}
		catch let error {
			appLogger.error("Error on commit: \(error)")
			return false
		}
	}
}
