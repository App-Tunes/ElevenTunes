//
//  ActionTableView.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 14.02.21.
//

import Cocoa

class ActionTableView: NSTableView {
	@objc
	var enterAction: Selector?
	
	override func keyDown(with event: NSEvent) {
		guard !Keycodes.Either.enter.matches(event: event) else {
			if let enterAction = enterAction {
				target?.performSelector(onMainThread: enterAction, with: event, waitUntilDone: false)
			}
			
			return
		}
		
		super.keyDown(with: event)
	}
}

class ActionOutlineView: NSOutlineView {
	@objc
	var enterAction: Selector?
	
	override func keyDown(with event: NSEvent) {
		guard !Keycodes.Either.enter.matches(event: event) else {
			if let enterAction = enterAction {
				target?.performSelector(onMainThread: enterAction, with: event, waitUntilDone: false)
			}
			
			return
		}
				
		super.keyDown(with: event)
	}
}
