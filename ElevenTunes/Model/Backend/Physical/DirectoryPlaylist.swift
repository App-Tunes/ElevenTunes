//
//  DirectoryPlaylist+CoreDataClass.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 25.12.20.
//
//

import Foundation
import SwiftUI
import Combine

public class DirectoryPlaylistToken: PlaylistToken {
    enum CodingKeys: String, CodingKey {
      case url
    }

    enum InterpretationError: Error {
        case noDirectory
    }

    var url: URL
    
    init(_ url: URL) {
        self.url = url
        super.init()
    }
    
    public override var id: String { url.absoluteString }
    
    static func create(fromURL url: URL) throws -> DirectoryPlaylistToken {
        if !(try url.isFileDirectory()) {
            throw InterpretationError.noDirectory
        }

        return DirectoryPlaylistToken(url)
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        url = try container.decode(URL.self, forKey: .url)
        try super.init(from: decoder)
    }
    
    public override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(url, forKey: .url)
        try super.encode(to: encoder)
    }
    
    override func expand(_ context: Library) -> AnyPlaylist {
        DirectoryPlaylist(self, library: context)
    }
}

public class DirectoryPlaylist: RemotePlaylist {
    let library: Library
    let token: DirectoryPlaylistToken
    public override var asToken: PlaylistToken { token }
    
    static let _icon: Image = Image(systemName: "folder")
    public override var icon: Image { DirectoryPlaylist._icon }
    public override var accentColor: Color { .accentColor }
        
    public override func supportsChildren() -> Bool { true }
    
    init(_ token: DirectoryPlaylistToken, library: Library) {
        self.library = library
        self.token = token
        super.init()
        loadMinimal()
        contentSet.formUnion([.minimal, .attributes])
    }
    
    func loadMinimal() {
        _attributes.value[PlaylistAttribute.title] = token.url.lastPathComponent
    }
    
    public override func load(atLeast mask: PlaylistContentMask) {
        let library = self.library
        
        contentSet.promise(mask) { promise in
            let url = token.url
            let interpreter = library.interpreter

            promise.fulfillingAny([.minimal, .attributes]) {
                loadMinimal()
            }
            
            guard promise.includesAny([.tracks, .children]) else {
                return
            }
            
            Future {
                try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: [.isDirectoryKey])
            }
            .flatMap {
                interpreter.interpret(urls: $0)
                    ?? Just([]).eraseError().eraseToAnyPublisher()
            }
            .map { (contents: [Content]) -> ([AnyTrack], [AnyPlaylist]) in
                let (tracks, children) = ContentInterpreter.collect(fromContents: contents)
                
                return (tracks.map { $0.expand(library) }, children.map { $0.expand(library) })
            }
            .onMain()
            .fulfillingAny([.tracks, .children], of: promise)
            .sink(receiveCompletion: appLogErrors(_:)) { [unowned self] (tracks, children) in
                _tracks.value = tracks
                _children.value = children
            }.store(in: &cancellables)
        }
        
        return
    }
}
