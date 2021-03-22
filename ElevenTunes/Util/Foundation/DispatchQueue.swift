//
//  DispatchQueue.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 23.03.21.
//

import Foundation

extension DispatchQueue {
	static func nowOrAsyncOnMain(_ fun: @escaping () -> Void) {
		if Thread.isMainThread {
			fun()
		}
		else {
			Self.main.async(execute: fun)
		}
	}
}
