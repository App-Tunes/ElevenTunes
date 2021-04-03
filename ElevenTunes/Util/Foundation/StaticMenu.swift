//
//  StaticMenu.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 14.02.21.
//

import Foundation

class StaticMenu {
	class Receiver {
		@objc func onClick(_ sender: Any) {
			let item = sender as! NSMenuItem
			let (_, action) = item.representedObject as! (Receiver, () -> Void)
			action()
		}
	}
	
	let menu = NSMenu()
	let receiver = Receiver()
	
	@discardableResult
	func addItem(withTitle title: String, disabled: Bool = false, callback: @escaping () -> Void) -> NSMenuItem {
		let item = NSMenuItem(title: title, action: #selector(Receiver.onClick(_:)), keyEquivalent: "")
		item.target = receiver
		item.isEnabled = !disabled
		if (!disabled) {
			item.representedObject = (receiver, callback)
		}
		menu.addItem(item)
		return item
	}
	
	func addSubmenu(withTitle title: String) -> StaticMenu {
		let item = NSMenuItem(title: title, action: #selector(Receiver.onClick(_:)), keyEquivalent: "")
		let submenu = StaticMenu()
		item.submenu = submenu.menu
		item.target = receiver
		item.representedObject = (receiver, {})
		menu.addItem(item)
		return submenu
	}
}
