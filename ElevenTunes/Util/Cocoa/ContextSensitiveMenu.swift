//
//  ContextSensitiveMenu.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 14.02.21.
//

import Cocoa

protocol NSOutlineViewContextSensitiveMenuDelegate {
	func currentMenu(forOutlineView outlineView: NSOutlineViewContextSensitiveMenu) -> NSMenu?
}

class NSOutlineViewContextSensitiveMenu : ActionOutlineView {
	// Only because we can't set clickedRows directly
	var _contextualClickedRows : IndexSet = IndexSet()
	var contextualClickedRows: IndexSet { _contextualClickedRows }
	
	func clickedRows(at point: NSPoint) -> IndexSet {
		let clickedRow = row(at: point)
		return selectedRowIndexes.contains(clickedRow)
			? selectedRowIndexes
			: IndexSet(integer: clickedRow)
	}

	override func menu(for event: NSEvent) -> NSMenu? {
		if let delegate = (self.delegate as? NSOutlineViewContextSensitiveMenuDelegate) {
			_contextualClickedRows = clickedRows(at: convert(event.locationInWindow, from: nil))
			// Can't return menu, otherwise outline doesn't get drawn
			menu = delegate.currentMenu(forOutlineView: self)
			return super.menu(for: event)
		}
		
		return super.menu(for: event)
	}
}

protocol NSTableViewContextSensitiveMenuDelegate {
	func currentMenu(forTableView tableView: NSTableViewContextSensitiveMenu) -> NSMenu?
}

class NSTableViewContextSensitiveMenu : ActionTableView {
	// Only because we can't set clickedRows directly
	var _contextualClickedRows : IndexSet = IndexSet()
	var contextualClickedRows: IndexSet {
		return _contextualClickedRows
	}
	
	func clickedRows(at point: NSPoint) -> IndexSet {
		let clickedRow = self.row(at: point)
		return selectedRowIndexes.contains(clickedRow)
			? selectedRowIndexes
			: IndexSet(integer: clickedRow)
	}
	
	override func menu(for event: NSEvent) -> NSMenu? {
		if let delegate = (self.delegate as? NSTableViewContextSensitiveMenuDelegate) {
			_contextualClickedRows = clickedRows(at: convert(event.locationInWindow, from: nil))
			menu = delegate.currentMenu(forTableView: self)
			// Can't return menu, otherwise outline doesn't get drawn
			return super.menu(for: event)
		}
		
		return super.menu(for: event)
	}
}
