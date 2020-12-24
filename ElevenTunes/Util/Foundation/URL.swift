//
//  URL.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 24.12.20.
//

import Foundation

extension URL {
    func isFileDirectory() throws -> Bool {
        if !isFileURL { return false }
        return try self.resourceValues(forKeys: [.isDirectoryKey]).isDirectory ?? false
    }
}
