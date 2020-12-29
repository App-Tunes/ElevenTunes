//
//  NSLock.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 29.12.20.
//

import Foundation

extension NSLock {
    func perform<R>(_ block: () throws -> R) rethrows -> R {
        lock()
        let r = try block()
        unlock()
        return r
    }
}
