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
    
    var defaultPlaylist: URL?
    
    init() {
        
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        defaultPlaylist = try container.decodeIfPresent(URL.self, forKey: .defaultPlaylist)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(defaultPlaylist, forKey: .defaultPlaylist)
    }

    var spotify: Spotify { GlobalSettingsLevel.instance.spotify }
}

class LibraryDocument: BSManagedDocument {
    override init() {
        settings = LibrarySettingsLevel()
        super.init()
        fileType = "ivorius.eleventunes.library"
        _library = Library(managedObjectContext: managedObjectContext!, settings: settings)
    }

    @Published var settings: LibrarySettingsLevel {
        didSet {
            _library = Library(managedObjectContext: managedObjectContext!, settings: settings)
        }
    }
    
    private var _library: Library?
    var library: Library { _library! }

    override class var autosavesInPlace: Bool {
        return true
    }

    override func makeWindowControllers() {
        // Create the SwiftUI view and set the context as the value for the managedObjectContext environment keyPath.
        // Add `@Environment(\.managedObjectContext)` in the views that will need the context.
        let contentView = ContentView()
            .environment(\.managedObjectContext, self.managedObjectContext!)
            .environment(\.library, library)
            .environment(\.player, library.player)

        // Create the window and set the content view.
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 300),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered, defer: false)

        window.toolbar = NSToolbar()
        window.toolbarStyle = .unifiedCompact
        window.titlebarAppearsTransparent = true

        window.isReleasedWhenClosed = false
        window.center()
        window.contentView = NSHostingView(rootView: contentView)
        let windowController = NSWindowController(window: window)
        self.addWindowController(windowController)
        
        // So it doesn't cover the rest of the GUI
        if !window.constrainMaxTitleSize(110) {
            appLogger.error("Failed to constrain window title size")
        }
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
