//
//  PlaylistsContextMenu.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 31.12.20.
//

import Foundation

import Foundation
import SwiftUI
import AppKit

class PlaylistsContextMenu {
    let playlist: AnyPlaylist
    
    init(playlist: AnyPlaylist) {
        self.playlist = playlist
    }
    
    func callAsFunction() -> AnyView {
        AnyView(VStack {
            if playlist.hasCaches {
                Button(action: {
                    self.playlist.invalidateCaches(.all)
                }) {
                    Image(systemName: "arrow.clockwise")
                    Text("Reload Metadata")
                }
            }
            
            if let origin = playlist.origin {
                Button(action: {
                    NSWorkspace.shared.open(origin)
                }) {
                    Image(systemName: "link")
                    Text("Visit Origin")
                }
            }
        })
    }
}
