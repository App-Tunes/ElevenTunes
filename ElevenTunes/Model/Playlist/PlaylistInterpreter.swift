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

class PlaylistDropInterpreter<Playlist: AnyPlaylist>: DropDelegate {
    let interpreter: ContentInterpreter
    let parent: Playlist
    
    var cancellables = Set<AnyCancellable>()
    
    init(_ interpreter: ContentInterpreter, parent: Playlist) {
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
            .map { ContentInterpreter.collect(fromContents: $0) }
            .onMain()
            .sink(receiveCompletion: appLogErrors(_:)) { (tracks, playlists) in
                playlist.add(tracks: tracks)
                playlist.add(children: playlists)
            }
            .store(in: &cancellables)

        return true
    }
}
