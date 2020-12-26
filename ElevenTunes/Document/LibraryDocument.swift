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
        spotify = AppDelegate.shared.spotify

        super.init()
        _library = Library(managedObjectContext: managedObjectContext!)
        _interpreter = ContentInterpreter.createDefault(spotify: spotify)
    }
    
    let spotify: Spotify
    private var _interpreter: ContentInterpreter?
    var interpreter: ContentInterpreter { _interpreter! }
    
    private var _library: Library?
    var library: Library { _library! }

    override class var autosavesInPlace: Bool {
        return true
    }

    override func makeWindowControllers() {
        // Create the SwiftUI view and set the context as the value for the managedObjectContext environment keyPath.
        // Add `@Environment(\.managedObjectContext)` in the views that will need the context.
        let contentView = ContentView(library: .constant(library))
            .environment(\.managedObjectContext, self.managedObjectContext!)
            .environment(\.interpreter, interpreter)
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
