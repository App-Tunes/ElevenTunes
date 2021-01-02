//
//  NSWindow.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 02.01.21.
//

import AppKit

extension NSWindow {
    func constrainMaxTitleSize(_ to: CGFloat) -> Bool {
        guard
            let frame = contentView?.superview,
            let titleBarContainer = frame.subviews.first(where: { $0.className == "NSTitlebarContainerView" }),
            let titlebar = titleBarContainer.subviews.first(where: { $0.className == "NSTitlebarView" }),
            let toolbar = titlebar.subviews.first(where:{ $0.className == "NSToolbarView" })
        else {
            appLogger.error("Failed to constrain title bar size.")
            return false
        }
        
        var didFindAny = false
        
        for view in flatSequence(first: [toolbar], next: { $0.subviews }) {
            if view is NSTextField {
                view.addConstraint(.init(item: view, attribute: .width, relatedBy: .lessThanOrEqual, toItem: nil, attribute: .notAnAttribute, multiplier: 0, constant: 150))
                didFindAny = true
            }
        }
        
        return didFindAny
    }
}
