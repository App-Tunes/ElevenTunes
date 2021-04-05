//
//  LibraryDocument.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 24.12.20.
//

import Cocoa
import Combine
import SwiftUI
import CoreData

class LibrarySettingsLevel: SettingsLevel, Codable {
    enum CodingKeys: String, CodingKey {
        case defaultPlaylist
    }
    
    var defaultPlaylist: UUID?
    
    init() {
        
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        defaultPlaylist = try container.decodeIfPresent(UUID.self, forKey: .defaultPlaylist)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(defaultPlaylist, forKey: .defaultPlaylist)
    }

    var spotify: Spotify { GlobalSettingsLevel.instance.spotify }
}

@objc(LibraryDocument) class LibraryDocument: BSManagedDocument {
    override init() {
        settings = LibrarySettingsLevel()
        super.init()
        fileType = "ivorius.eleventunes.library"
        managedObjectContext.automaticallyMergesChangesFromParent = true
        // Don't init library; read will be called
    }
    
    init(settings: LibrarySettingsLevel) {
        self.settings = settings
        super.init()
        fileType = "ivorius.eleventunes.library"
        managedObjectContext.automaticallyMergesChangesFromParent = true
    }
	
	// TODO Suboptimal... Where should this be created?
	private(set) lazy var library = Library(document: self)

    @Published var settings: LibrarySettingsLevel
    
    override func makeWindowControllers() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1000, height: 500),
			styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView, .unifiedTitleAndToolbar],
            backing: .buffered, defer: false)

        window.toolbar = NSToolbar()
        window.toolbarStyle = .unified
        window.titlebarAppearsTransparent = true
		window.titlebarSeparatorStyle = .none
		
		let titleBarVC = NSTitlebarAccessoryViewController()
		titleBarVC.view = NSHostingView(rootView: ToolbarView(player: library.player))
		titleBarVC.view.translatesAutoresizingMaskIntoConstraints = false
		titleBarVC.automaticallyAdjustsSize = true
		titleBarVC.layoutAttribute = .right
		window.addTitlebarAccessoryViewController(titleBarVC)

		window.isReleasedWhenClosed = false

		let libraryVC = LibraryViewController(nibName: nil, bundle: .main)
		libraryVC.toolbarView = titleBarVC.view
		libraryVC.library = library
		
		window.delegate = libraryVC
		window.contentViewController = libraryVC
        window.center()
		
        let windowController = NSWindowController(window: window)
        self.addWindowController(windowController)
        
		// Don't need this now since we have the toolbar
//        // So it doesn't cover the rest of the GUI
//        if !window.constrainMaxTitleSize(110) {
//            appLogger.error("Failed to constrain window title size")
//        }
        
        updateChangeCount(.changeCleared)
    }
    
	func `import`(tracks: [TrackToken]) throws {
        try library.import(tracks, to: nil, atIndex: nil)
    }

	func `import`(playlists: [PlaylistToken]) throws {
		guard let defaultPlaylistID = settings.defaultPlaylist else {
			throw LibraryPlaylist.ImportError.noDefaultPlaylist
		}
		guard let playlist = try? managedObjectContext.fetch(DBPlaylist.createFetchRequest(id: defaultPlaylistID)).first else {
			throw LibraryPlaylist.ImportError.noDefaultPlaylist
		}
		
		try library.import(playlists, to: playlist, atIndex: nil)
	}
	
    override func additionalContent(for absoluteURL: URL!, saveOperation: NSDocument.SaveOperationType) throws -> Any {
        settings
    }
    
    override func writeAdditionalContent(_ content: Any!, to absoluteURL: URL!, originalContentsURL absoluteOriginalContentsURL: URL!) throws {
		managedObjectContext.persistentStoreCoordinator!.name = absoluteURL.description
		
        if let content = content as? LibrarySettingsLevel {
            let target = absoluteURL.appendingPathComponent("Settings.json")
            let encoder = JSONEncoder()
            let data = try encoder.encode(content)
            try data.write(to: target)
        }
    }
    
    override func readAdditionalContent(from absoluteURL: URL!) throws {
		managedObjectContext.persistentStoreCoordinator!.name = absoluteURL.description

        let target = absoluteURL.appendingPathComponent("Settings.json")
        let decoder = JSONDecoder()
        let data = try Data(contentsOf: target)
        settings = try decoder.decode(LibrarySettingsLevel.self, from: data)
    }
}
