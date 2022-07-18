//
//  NSTableView.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 07.03.21.
//

import Cocoa

extension NSTableView {
	var clickedRows: [Int] {
		if isRowSelected(clickedRow) {
			return Array(selectedRowIndexes)
		}
		return [clickedRow]
	}
		
	func tableColumn(withIdentifier identifier: NSUserInterfaceItemIdentifier) -> NSTableColumn? {
		return tableColumns[safe: column(withIdentifier: identifier)]
	}
	
	func scrollRowToTop(_ row: Int) {
		let headerPart = headerView?.frame.height ?? 0
		scroll(NSPoint(x: 0, y: CGFloat(row) * (rowHeight + intercellSpacing.height) - headerPart))
	}
}

extension NSTableColumn {
	var widthRange: ClosedRange<CGFloat> {
		get { minWidth...maxWidth }
		set {
			minWidth = newValue.lowerBound
			maxWidth = newValue.upperBound
		}
	}
}
