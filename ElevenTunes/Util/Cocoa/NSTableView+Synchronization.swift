//
//  NSTableView+Synchronization.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 09.03.21.
//

import Cocoa

extension NSTableView {
	class ActiveSynchronizer {
		let tableView: NSTableView
		
		var moveObserver: NSObjectProtocol?
		var resizeObserver: NSObjectProtocol?
		var visibleObserver: NSObjectProtocol?

		var key: NSTableView.AutosaveName? {
			tableView.autosaveName
		}
		
		init(tableView: NSTableView) {
			self.tableView = tableView
		}
		
		func attach() {
			moveObserver = NotificationCenter.default.addObserver(forName: NSTableView.columnDidMoveNotification, object: nil, queue: .main) { [unowned self] notification in
				let tableView = notification.object as! NSTableView

				guard tableView != self.tableView, tableView.autosaveName == self.tableView.autosaveName else {
					return
				}
				
				let oldIndex = notification.userInfo!["NSOldColumn"] as! Int
				let newIndex = notification.userInfo!["NSNewColumn"] as! Int
				let column = tableView.tableColumns[newIndex]

				guard self.tableView.column(withIdentifier: column.identifier) == oldIndex else {
					return
				}
				
				self.tableView.moveColumn(oldIndex, toColumn: newIndex)
			}

			resizeObserver = NotificationCenter.default.addObserver(forName: NSTableView.columnDidResizeNotification, object: nil, queue: .main) { [unowned self] notification in
				let tableView = notification.object as! NSTableView
				
				guard tableView != self.tableView, tableView.autosaveName == self.tableView.autosaveName else {
					return
				}

				let column = notification.userInfo!["NSTableColumn"] as! NSTableColumn
				let selfColumn = self.tableView.tableColumn(withIdentifier: column.identifier)!
				
				if selfColumn.width != column.width {
					selfColumn.width = column.width
				}
			}

			visibleObserver = NotificationCenter.default.addObserver(forName: NSTableView.columnDidChangeVisibilityNotification, object: nil, queue: .main) { [unowned self] notification in
				let tableView = notification.object as! NSTableView
				
				guard tableView != self.tableView, tableView.autosaveName == self.tableView.autosaveName else {
					return
				}

				let column = notification.userInfo!["NSTableColumn"] as! NSTableColumn
				let selfColumn = self.tableView.tableColumn(withIdentifier: column.identifier)!
				
				if selfColumn.isHidden != column.isHidden {
					selfColumn.isHidden = column.isHidden
				}
			}
		}
	}
}
