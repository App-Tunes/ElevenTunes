//
//  PlaylistsViewController.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 14.02.21.
//

import Cocoa
import Combine

class PlaylistsViewController: NSViewController {
	@IBOutlet weak var outlineView: NSOutlineView! = nil
	var expandExtension: NSOutlineView.DelayedAutoExpander! = nil
		
	var library: Library
	var directory: Playlist {
		didSet {
			directoryItem = Item(playlist: directory.backend, parent: nil, delegate: self)
		}
	}
	
	var directoryItem: Item! {
		didSet {
			outlineView?.reloadData()
		}
	}
	
	var navigator: Navigator {
		didSet { observeNavigator() }
	}
	var navigationObservation: AnyCancellable?
	
	var dummyPlaylist: Item!
	
	var cancellables = Set<AnyCancellable>()
	
	init(_ directory: Playlist, library: Library, navigator: Navigator) {
		self.directory = directory
		self.library = library
		self.navigator = navigator
		super.init(nibName: nil, bundle: .main)
		directoryItem = Item(playlist: directory.backend, parent: nil, delegate: self)
		directoryItem.isDemanding = true
		dummyPlaylist = Item(playlist: TransientPlaylist(.tracks, attributes: .init()), parent: nil, delegate: self)
		observeNavigator()
		NotificationCenter.default.addObserver(self, selector: #selector(onNewPlaylist(notification:)), name: NewPlaylistView.newPlaylistNotification, object: nil)
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		// TODO Autosave information? I don't think the outline view can do it in a delayed manner.
		expandExtension = .init(outlineView: outlineView, timeLimit: 5)
		if let defaultPlaylist = library.defaultPlaylist {
			expandExtension.expand = [defaultPlaylist.uuid.uuidString]
		}
		
		outlineView.autosaveExpandedItems = true
		outlineView.autosaveName = library.managedObjectContext.persistentStoreCoordinator?.name.map {
			"playlists-\($0)"
		}
		
		outlineView.registerForDraggedTypes(PlaylistInterpreter.standard.types.map { .init(rawValue: $0.identifier ) })
		outlineView.registerForDraggedTypes(TrackInterpreter.standard.types.map { .init(rawValue: $0.identifier ) })
		outlineView.registerForDraggedTypes([.init(PlaylistsExportManager.playlistsIdentifier)])
				
		// Auto-expand the default playlist at launch
		if let defaultPlaylist = library.defaultPlaylist,
		   let item = item(forCache: defaultPlaylist) {
			outlineView.expandItem(item)
		}
    }
	
	@objc func onNewPlaylist(notification: NSNotification) {
		guard let playlist = notification.userInfo?["playlist"] as? AnyPlaylist else {
			return
		}
		
		if
			let playlist = playlist as? LibraryPlaylist,
			let defaultPlaylist = playlist.library?.defaultPlaylist,
			let item = item(forCache: defaultPlaylist)
		{
			outlineView.animator().expandItem(item)
			return
		}
		
		// TODO Expand full path? May never be required
		guard let item = item(forPlaylistID: playlist.id) else {
			return
		}
		
		outlineView.animator().expandItem(item)
	}
}
