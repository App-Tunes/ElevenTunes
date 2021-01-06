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
    let interpreter: ContentInterpreter
    let parent: AnyPlaylist
    
    var cancellables = Set<AnyCancellable>()
    
    init(_ interpreter: ContentInterpreter, parent: AnyPlaylist) {
        self.interpreter = interpreter
        self.parent = parent
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
        interpreted
            .map { ContentInterpreter.library(fromContents: $0, name: "Imported Items") }
            .onMain()
            .sink(receiveCompletion: appLogErrors(_:)) { library in
                playlist.import(library: library)
            }
            .store(in: &cancellables)

        return true
    }
}
