//
//  NSOutlineView.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 07.03.21.
//

import Cocoa

extension NSOutlineView {
	func edit(row: Int, with event: NSEvent?, select: Bool) {
		editColumn(0, row: row, with: event, select: select)
	}
	
	func animateDifference<Element : Equatable>(childrenOf parent: Any?, from: [Element]?, to: [Element]?) {
		let fromCount = from?.count ?? 0
		let toCount = to?.count ?? 0
		
		guard abs(fromCount - toCount) < 100 else {
			// Give up, this will look shite anyhow
			reloadItem(parent, reloadChildren: true)
			return
		}
		
		if let from = from, let to = to, let editDiff = from.editDifference(from: to) {
			guard editDiff.array.count < 100 else {
				// Give up, this will look shite anyhow
				reloadItem(parent, reloadChildren: true)
				return
			}
			
			switch editDiff {
			case .remove(let removed):
				removeItems(at: IndexSet(removed), inParent: parent, withAnimation: .slideDown)
			case .add(let added):
				insertItems(at: IndexSet(added), inParent: parent, withAnimation: .slideUp)
			}
		}
		else if let from = from, let to = to, let movement = from.editMovement(to: to) {
			for (src, dst) in movement {
				moveItem(at: src, inParent: parent, to: dst, inParent: parent)
			}
		}
		else {
			reloadData()
		}
	}

	func animateDelete(items: [Any]) {
		guard items.count < 100 else {
			reloadData()
			return
		}
		
		for element in items {
			let idx = childIndex(forItem: element)
			if idx >= 0 {
				removeItems(at: IndexSet(integer: idx), inParent: parent(forItem: element), withAnimation: .slideDown)
			}
		}
	}
	
	func animateInsert<T>(items: [T], position: (T) -> (Int, T?)?) {
		guard items.count < 100 else {
			reloadData()
			return
		}
		
		let positioned = items.compactMap(position).sorted {
			return $0.0 < $1.0
		}
		
		for (pos, parent) in positioned {
			insertItems(at: IndexSet(integer: pos), inParent: parent, withAnimation: .slideUp)
		}
	}
	
	func reloadItems<C : Collection, E>(_ items: C, reloadChildren: Bool = false) where C.Element == E? {
		if items.contains(where: { $0 == nil }) {
			reloadData()
			return
		}
		
		for case let item as AnyObject in items {
			let parent = self.parent(forItem: item)
			let idx = childIndex(forItem: item)
			guard (dataSource?.outlineView?(self, numberOfChildrenOfItem: parent) ?? 0) > idx else {
				// We have been deleted or something, but the parent will be reloaded anyway
				continue
			}
			
			reloadItem(item, reloadChildren: reloadChildren)
		}
	}
	
	func children(ofItem item: Any?) -> [Any] {
		let number = numberOfChildren(ofItem: item)
		return (0..<number).map {
			self.child($0, ofItem: item)!
		}
	}
	
	func view(atColumn column: Int, forItem item: Any?, makeIfNecessary: Bool) -> NSView? {
		let itemRow = row(forItem: item)
		return itemRow >= 0 ? view(atColumn: column, row: itemRow, makeIfNecessary: makeIfNecessary) : nil
	}
	
	@discardableResult
	func toggleItemExpanded(_ item: Any?) -> Bool {
		guard isItemExpanded(item) else {
			(animator() as NSOutlineView).expandItem(item)
			return true
		}

		(animator() as NSOutlineView).collapseItem(item)
		return false
	}
}
