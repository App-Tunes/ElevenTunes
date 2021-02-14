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
	
	func addItem(withTitle title: String, callback: @escaping () -> Void) {
		let item = NSMenuItem(title: title, action: #selector(Receiver.onClick(_:)), keyEquivalent: "")
		item.target = receiver
		item.representedObject = (receiver, callback)
		menu.addItem(item)
	}
}
