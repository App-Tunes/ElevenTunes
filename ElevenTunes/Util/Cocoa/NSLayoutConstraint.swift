//
//  NSLayoutConstraint.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 14.02.21.
//

import Cocoa

extension NSLayoutConstraint {
	static func copyLayout(from container: NSView, for view: NSView) -> [NSLayoutConstraint] {
		return [
			NSLayoutConstraint(item: view, attribute: .leading, relatedBy: .equal, toItem: container, attribute: .leading, multiplier: 1, constant: 0),
			NSLayoutConstraint(item: view, attribute: .trailing, relatedBy: .equal, toItem: container, attribute: .trailing, multiplier: 1, constant: 0),
			NSLayoutConstraint(item: view, attribute: .top, relatedBy: .equal, toItem: container, attribute: .top, multiplier: 1, constant: 0),
			NSLayoutConstraint(item: view, attribute: .bottom, relatedBy: .equal, toItem: container, attribute: .bottom, multiplier: 1, constant: 0),
		]
	}
}

extension NSView {
	func setFullSizeContent(_ view: NSView?) {
		subviews = []
		
		guard let view = view else {
			return
		}
		
		view.frame = bounds
		addSubview(view)
		
		addConstraints(NSLayoutConstraint.copyLayout(from: self, for: view))
	}
}
