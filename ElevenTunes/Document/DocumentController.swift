//
//  DocumentController.swift
//  Test 3
//
//  Created by Lukas Tenbrink on 25.12.20.
//

import AppKit

class DocumentController: NSDocumentController {
    override func makeUntitledDocument(ofType typeName: String) throws -> NSDocument {
        let doc = LibraryDocument()
//        doc.library.mainPlaylist.add(children: [
//            LibraryMock.playlist("Playlist 1"),
//            LibraryMock.playlist("Playlist 2")
//        ])
        return doc
    }
}
