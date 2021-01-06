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
        
        let defaultPlaylistsModel = [
            TransientPlaylist(.playlists, attributes: .init([
                .title: "Playlists"
            ]))
        ]
        let (_, playlists) = Library.convert(
            DirectLibrary(allPlaylists: defaultPlaylistsModel),
            context: doc.managedObjectContext!
        )
        doc.library.defaultPlaylist = playlists[0]

        return doc
    }
    
    override var defaultType: String? { "ivorius.eleventunes.library" }
    
    override var documentClassNames: [String] { ["LibraryDocument"] }
    
    override func documentClass(forType typeName: String) -> AnyClass? {
        if typeName == "ivorius.eleventunes.library" {
            return LibraryDocument.self
        }
        
        return super.documentClass(forType: typeName)
    }
}
