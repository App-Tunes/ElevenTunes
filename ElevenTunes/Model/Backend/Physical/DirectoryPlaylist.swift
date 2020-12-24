//
//  DirectoryPlaylist.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 20.12.20.
//

import Foundation
import SwiftUI
import Combine

class DirectoryPlaylist: PlaylistBackend {
    var url: URL
    
    init(_ url: URL) {
        self.url = url
    }
    
    static func create(fromURL url: URL) -> Playlist {
        let playlistName = url.lastPathComponent
        
        return Playlist(DirectoryPlaylist(url), attributes: .init([
            AnyTypedKey.ptitle.id: playlistName
        ]))
    }
    
    var icon: Image? { Image(systemName: "folder.fill") }

    func load() -> AnyPublisher<([Track], [Playlist]), Error> {
        let url = self.url
        
        return Future {
            let manager = FileManager.default
            
            var tracks: [Track] = []
            var children: [Playlist] = []
            
            for url in try manager.contentsOfDirectory(at: url, includingPropertiesForKeys: [.isDirectoryKey]) {
                guard
                    let attributes = try? url.resourceValues(forKeys: [.isDirectoryKey]),
                    let isDirectory = attributes.isDirectory
                else {
                    continue
                }
                
                if isDirectory {
                    children.append(DirectoryPlaylist.create(fromURL: url))
                }
                else {
                    // TODO Interpret children files, e.g. M3U
                    if let track = try? FileTrack.create(fromURL: url) {
                        tracks.append(track)
                    }
                }
            }

            return (tracks, children)
        }.eraseToAnyPublisher()
    }
    
    func add(tracks: [Track]) -> Bool {
        // TODO
        return false
    }
    
    func add(children: [Playlist]) -> Bool {
        // TODO
        return false
    }
}
