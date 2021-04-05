//
//  LibraryViewController.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 05.04.21.
//

import Cocoa
import SwiftUI

class LibraryViewController: NSViewController {
	@IBOutlet weak var _splitView: NSSplitView!
	
	var library: Library! {
		didSet {
			mainPlaylist = LibraryPlaylist(library: library, playContext: library.playContext)
			navigator = Navigator(root: Playlist(mainPlaylist))
		}
	}
	
	var toolbarView: NSView?
	var mainPlaylist: LibraryPlaylist!
	var navigator: Navigator!

	@IBOutlet weak var _leftView: AnyNSHostingView!
	@IBOutlet weak var _rightView: AnyNSHostingView!
	
	var toolbarSizeObservation: NSObjectProtocol?
	
	override func viewDidLoad() {
        super.viewDidLoad()

		_leftView.rootView = AnyView(
			NavigatorView(navigator: navigator)
				.environment(\.managedObjectContext, library.managedObjectContext)
				.environment(\.library, library)
				.environment(\.player, library.player)
		)
		
		_rightView.rootView = AnyView(
			MainContentView(navigator: navigator)
				.environment(\.managedObjectContext, library.managedObjectContext)
				.environment(\.library, library)
				.environment(\.player, library.player)
		)
		
		_splitView.setHoldingPriority(.defaultLow + 0.5, forSubviewAt: 0)
		
		toolbarSizeObservation = NotificationCenter.default.addObserver(forName: NSView.frameDidChangeNotification, object: _rightView, queue: .main) { [weak self] notification in
			self?.updateToolbarSize()
		}
		
		updateToolbarSize()
    }
	
	override func viewDidAppear() {
		updateToolbarSize()
	}
	
	func updateToolbarSize() {
		if let window = view.window {
			toolbarView?.frame.size.width = min(_rightView.frame.size.width, window.frame.size.width - 250)
		}
	}
}

extension LibraryViewController: NSSplitViewDelegate {
	func splitView(_ splitView: NSSplitView, canCollapseSubview subview: NSView) -> Bool {
		subview === _leftView
	}
}

extension LibraryViewController: NSWindowDelegate {
	func window(_ window: NSWindow, willUseFullScreenPresentationOptions proposedOptions: NSApplication.PresentationOptions = []) -> NSApplication.PresentationOptions {
		window.titlebarAppearsTransparent = true
		return proposedOptions
	}
}
