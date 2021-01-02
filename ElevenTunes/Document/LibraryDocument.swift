//
//  LibraryDocument.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 24.12.20.
//

import Cocoa
import Combine
import SwiftUI

class LibraryDocument: NSPersistentDocument {
    override init() {
        super.init()
        let defaultContext = managedObjectContext!
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.persistentStoreCoordinator = defaultContext.persistentStoreCoordinator
        context.name = defaultContext.name
        managedObjectContext = context
        
        _library = Library(managedObjectContext: context, spotify: AppDelegate.shared.spotify)
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
    
    override func configurePersistentStoreCoordinator(for url: URL, ofType fileType: String, modelConfiguration configuration: String?, storeOptions: [String : Any]? = nil) throws {
        var options = storeOptions ?? [:]
        options[NSMigratePersistentStoresAutomaticallyOption] = true
        options[NSInferMappingModelAutomaticallyOption] = true
        try super.configurePersistentStoreCoordinator(for: url, ofType: fileType, modelConfiguration: configuration, storeOptions: options)
    }
}
