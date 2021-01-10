//
//  TracksContextMenu.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 31.12.20.
//

import Foundation
import SwiftUI
import AppKit

class TracksContextMenu {
    let tracks: [AnyTrack]
    let idx: Int
    let selected: Set<Int>
    
    init(tracks: [AnyTrack], idx: Int, selected: Set<Int>) {
        self.tracks = tracks
        self.idx = idx
        self.selected = selected
    }
    
    lazy var sindices: Set<Int> = selected.alIfContains(idx)
    lazy var stracks: [AnyTrack] = sindices.map { tracks[$0] }
    
    func callAsFunction() -> AnyView {
        AnyView(VStack {
            Button(action: {
				self.stracks.forEach { $0.invalidateCaches() }
            }) {
                Image(systemName: "arrow.clockwise")
                Text("Reload Metadata")
            }

            if let track = stracks.one, let origin = track.origin {
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
