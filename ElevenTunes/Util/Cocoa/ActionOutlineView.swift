//
//  ActionTableView.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 14.02.21.
//

import Cocoa

class ActionTableView: NSTableView {
	@objc var returnAction: Selector?
	
	override func keyDown(with event: NSEvent) {
		guard !Keycodes.Either.enter.matches(event: event) else {
			if let returnAction = returnAction {
				target?.performSelector(onMainThread: returnAction, with: event, waitUntilDone: false)
			}
			
			return
		}
		
		super.keyDown(with: event)
	}
}

class ActionOutlineView: NSOutlineView {
	@objc var returnAction: Selector?
	
	override func keyDown(with event: NSEvent) {
		guard !Keycodes.Either.enter.matches(event: event) else {
			if let returnAction = returnAction {
				target?.performSelector(onMainThread: returnAction, with: event, waitUntilDone: false)
			}
			
			return
		}
				
		super.keyDown(with: event)
	}
}
