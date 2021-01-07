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

    @Published var settings: LibrarySettingsLevel
    
    override func makeWindowControllers() {
        // Create the SwiftUI view and set the context as the value for the managedObjectContext environment keyPath.
        // Add `@Environment(\.managedObjectContext)` in the views that will need the context.
        let library = Library(managedObjectContext: managedObjectContext, settings: settings)
        let contentView = ContentView(mainPlaylist: Playlist(library.mainPlaylist))
            .environment(\.managedObjectContext, self.managedObjectContext!)
            .environment(\.library, library)
            .environment(\.player, library.player)

        // Create the window and set the content view.
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1000, height: 500),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered, defer: false)

        window.toolbar = NSToolbar()
        window.toolbarStyle = .unifiedCompact
        window.titlebarAppearsTransparent = true

        window.isReleasedWhenClosed = false
        window.contentView = NSHostingView(rootView: contentView)
        window.center()
        let windowController = NSWindowController(window: window)
        self.addWindowController(windowController)
        
        // So it doesn't cover the rest of the GUI
        if !window.constrainMaxTitleSize(110) {
            appLogger.error("Failed to constrain window title size")
        }
        
        updateChangeCount(.changeCleared)
    }
    
    func `import`(_ dlibrary: AnyLibrary) -> Bool {
        guard let defaultPlaylistID = settings.defaultPlaylist else {
            return false
        }
        guard let playlist = try? managedObjectContext.fetch(DBPlaylist.createFetchRequest(id: defaultPlaylistID)).first else {
            return false
        }
                
        return Library.import(dlibrary, to: playlist)
    }

    override func additionalContent(for absoluteURL: URL!, saveOperation: NSDocument.SaveOperationType) throws -> Any {
        settings
    }
    
    override func writeAdditionalContent(_ content: Any!, to absoluteURL: URL!, originalContentsURL absoluteOriginalContentsURL: URL!) throws {
        if let content = content as? LibrarySettingsLevel {
            let target = absoluteURL.appendingPathComponent("Settings.json")
            let encoder = JSONEncoder()
            let data = try encoder.encode(content)
            try data.write(to: target)
        }
    }
    
    override func readAdditionalContent(from absoluteURL: URL!) throws {
        let target = absoluteURL.appendingPathComponent("Settings.json")
        let decoder = JSONDecoder()
        let data = try Data(contentsOf: target)
        settings = try decoder.decode(LibrarySettingsLevel.self, from: data)
    }
}
