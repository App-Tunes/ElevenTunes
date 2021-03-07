//
//  NSTableView.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 07.03.21.
//

import Cocoa

extension NSTableColumn {
	var widthRange: ClosedRange<CGFloat> {
		get { minWidth...maxWidth }
		set {
			minWidth = newValue.lowerBound
			maxWidth = newValue.upperBound
		}
	}
}
