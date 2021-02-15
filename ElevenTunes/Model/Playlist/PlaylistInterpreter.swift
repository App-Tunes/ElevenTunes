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
    
    let interpreter: ContentInterpreter
    let parent: AnyPlaylist
    let context: Context
    
    var cancellables = Set<AnyCancellable>()
    
    init(_ interpreter: ContentInterpreter, parent: AnyPlaylist, context: Context) {
        self.interpreter = interpreter
        self.parent = parent
        self.context = context
    }
    
    func dropEntered(info: DropInfo) {
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        guard let interpreted = interpreter.interpret(drop: info) else {
            return false
        }
        
        let playlist = self.parent
        let context = self.context
        interpreted
            .tryMap { ContentInterpreter.collect(fromContents: $0) }
            .onMain()
            .sink(receiveCompletion: appLogErrors(_:)) { library in
                if context == .tracks && !library.playlists.isEmpty {
                    // TODO Ask if the user wants to add all tracks of the playlist?
                    return
                }
                
				do {
					try playlist.import(library: library, toIndex: nil)
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
