//
//  DispatchSemaphore.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 03.04.21.
//

import Foundation

extension DispatchSemaphore {
	func waitAndDo<R>(_ fun: () throws -> R) rethrows -> R {
		wait()
		defer { signal() }
		return try fun()
	}
}
