//
//  DelayedAutoExpander.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 14.03.21.
//

import Cocoa

extension NSOutlineView {
	class DelayedAutoExpander : NSObject {
		let outlineView: NSOutlineView
		var autoExpands: Bool = true

		private var timer: Timer? = nil
		
		var expand: Set<String> = []

		init(outlineView: NSOutlineView, timeLimit: TimeInterval? = nil) {
			self.outlineView = outlineView
			super.init()
			
			if let timeLimit = timeLimit {
				timer = Timer.scheduledTimer(withTimeInterval: timeLimit, repeats: false) { [weak self] _ in
					self?.autoExpands = false
				}
			}
		}
		
		func willDisplayItem(_ item: Any?, withID id: String) {
			if autoExpands, expand.contains(id) {
				outlineView.expandItem(item)
				expand.remove(id)
			}
		}
	}
}
