//
//  NSTableView+Visibility.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 07.03.21.
//

import Cocoa

extension NSTableView {
	static let columnDidChangeVisibilityNotification = NSNotification.Name("NSTableViewColumnDidChangeVisibilityNotification")
	
	class ColumnHiddenExtension : NSObject, NSMenuDelegate {
		let tableView: NSTableView
		var titles: [NSUserInterfaceItemIdentifier: String] = [:]
		var affix: Set<NSUserInterfaceItemIdentifier>
		
		init(tableView: NSTableView, titles: [NSUserInterfaceItemIdentifier: String] = [:], affix: Set<NSUserInterfaceItemIdentifier> = Set()) {
			self.tableView = tableView
			self.titles = titles
			self.affix = affix
		}
		
		func attach() {
			tableView.headerView!.menu = NSMenu()
			tableView.headerView!.menu!.delegate = self
			
			updateMenu()
		}
		
		func updateMenu() {
			// might have been removed in the meantime
			guard let menu = tableView.headerView?.menu else {
				return
			}
			
			menu.removeAllItems()

			for column in tableView.tableColumns {
				guard !affix.contains(column.identifier) else {
					continue
				}
				
				let item = NSMenuItem(title: titles[column.identifier] ?? column.headerCell.stringValue, action: #selector(columnItemClicked(_:)), keyEquivalent: "")
				item.target = self
				
				item.state = column.isHidden ? .off : .on
				item.representedObject = column
				
				menu.addItem(item)
			}
		}
		
		func menuWillOpen(_ menu: NSMenu) {
			for item in menu.items {
				item.state = (item.representedObject as! NSTableColumn).isHidden ? .off : .on
			}
		}

		@IBAction func columnItemClicked(_ sender: Any) {
			let item = sender as! NSMenuItem
			let column = item.representedObject as! NSTableColumn
			
			let hide = !column.isHidden
			
			column.isHidden = hide
			item.state = hide ? .off : .on
			NotificationCenter.default.post(name: columnDidChangeVisibilityNotification, object: tableView, userInfo: ["NSTableColumn": column])

			tableView.sizeToFit()
		}
	}
}
