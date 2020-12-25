//
//  ElevenTunesDocument.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 15.12.20.
//

import SwiftUI
import UniformTypeIdentifiers

struct ElevenTunesDocument: FileDocument {
    var playlist: Playlist

    init(playlist: Playlist) {
        self.playlist = playlist
    }

    static var readableContentTypes: [UTType] {
        ContentInterpreter.types
    }
    
    static var writableContentTypes: [UTType] {
        ContentInterpreter.types
    }

    init(configuration: ReadConfiguration) throws {
        print(configuration)
        guard
            configuration.file.regularFileContents != nil
        else {
            throw CocoaError(.fileReadCorruptFile)
        }
        
        // TODO
        throw CocoaError(.fileReadCorruptFile)
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        throw CocoaError(.fileReadCorruptFile)
        
//        return .init(regularFileWithContents: data)
    }
}
