//
//  SettingsWindowController.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 25.12.20.
//

import Foundation
import SwiftUI

class SettingsWindowController: NSWindowController {
    init(content: AnyView) {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 300),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered, defer: false)
        window.toolbarStyle = .preference
        window.toolbar = NSToolbar()
        window.isReleasedWhenClosed = false
        window.titlebarAppearsTransparent = true
        window.center()
        window.contentView = NSHostingView(rootView: content.edgesIgnoringSafeArea(.top))
        super.init(window: window)
    }
    
    required init?(coder: NSCoder) {
        nil
    }
}
