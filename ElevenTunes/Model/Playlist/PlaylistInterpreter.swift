//
//  PlaylistInterpreter.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 20.12.20.
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers
import Combine

class PlaylistDropInterpreter: DropDelegate {
    enum Context {
        case playlists, tracks
    }
    
    let parent: AnyPlaylist
    
    var cancellables = Set<AnyCancellable>()
    
	init(parent: AnyPlaylist) {
        self.parent = parent
    }
    
    func dropEntered(info: DropInfo) {
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .move)
    }

    func performDrop(info: DropInfo) -> Bool {
		guard let interpreted = TrackInterpreter.standard.interpret(drop: info) else {
            return false
        }
        
        let playlist = self.parent
		
        interpreted
            .onMain()
            .sink(receiveCompletion: appLogErrors(_:)) { tokens in
				do {
					try playlist.import(tracks: tokens, toIndex: nil)
				}
				catch let error {
					NSAlert.warning(
						title: "Import Failure",
						text: String(describing: error)
					)
				}
            }
            .store(in: &cancellables)

        return true
    }
}
