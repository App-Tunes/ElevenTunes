//
//  LibraryDocument.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 24.12.20.
//

import Cocoa
import Combine
import SwiftUI

class LibraryDocument: BSManagedDocument {
    override init() {
        super.init()
        fileType = "ivorius.eleventunes.library"
        let settings = GlobalSettingsLevel.instance
        _library = Library(managedObjectContext: managedObjectContext!, spotify: settings.spotify)
        Swift.print(managedObjectContext.concurrencyType.rawValue)
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
}
