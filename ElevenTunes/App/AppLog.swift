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
