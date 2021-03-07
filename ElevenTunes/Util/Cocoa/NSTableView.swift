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
	
	func animateDifference<Element : Equatable>(from: [Element]?, to: [Element]?) {
		if let from = from, let to = to, let editDiff = from.editDifference(from: to) {
			guard editDiff.array.count < 100 else {
				// Give up, this will look shite anyhow
				reloadData()
				return
			}
			
			switch editDiff {
			case .remove(let removed):
				removeRows(at: IndexSet(removed), withAnimation: .slideDown)
			case .add(let added):
				insertRows(at: IndexSet(added), withAnimation: .slideUp)
			}
		}
		else if let from = from, let to = to, let movement = from.editMovement(to: to) {
			for (src, dst) in movement {
				moveRow(at: src, to: dst)
			}
		}
		else {
			reloadData()
		}
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
