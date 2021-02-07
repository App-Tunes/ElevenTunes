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
    let tracks: [Track]
    
    init(tracks: [Track], idx: Int, selected: Set<Int>) {
        let sindices = selected.allIfContains(idx)
		self.tracks = sindices.map { tracks[$0] }
    }
        
    func callAsFunction() -> some View {
        VStack {
			let tracks = self.tracks

            Button(action: {
				tracks.forEach { $0.backend.invalidateCaches() }
            }) {
                Image(systemName: "arrow.clockwise")
                Text("Reload Metadata")
            }

			if let track = tracks.one, let origin = track.backend.origin {
                Button(action: {
                    NSWorkspace.shared.open(origin)
                }) {
                    Image(systemName: "link")
                    Text("Visit Origin")
                }
            }
        }
    }
}
