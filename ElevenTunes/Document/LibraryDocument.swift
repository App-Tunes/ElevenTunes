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
        // Add your subclass-specific initialization here.
    }
    
    var mainPlaylist: Playlist = LibraryMock.directory()

    override class var autosavesInPlace: Bool {
        return true
    }

    override func makeWindowControllers() {
        // Create the SwiftUI view and set the context as the value for the managedObjectContext environment keyPath.
        // Add `@Environment(\.managedObjectContext)` in the views that will need the context.
        let contentView = ContentView(document: .constant(self))
            .environment(\.managedObjectContext, self.managedObjectContext!)
            .environment(\.interpreter, AppDelegate.shared.interpreter)
            .environment(\.spotify, AppDelegate.shared.spotify)

        // Create the window and set the content view.
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 300),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.center()
        window.contentView = NSHostingView(rootView: contentView)
        let windowController = NSWindowController(window: window)
        self.addWindowController(windowController)
    }
}
