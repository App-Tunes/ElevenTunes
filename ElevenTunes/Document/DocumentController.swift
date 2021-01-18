//
//  DocumentController.swift
//  Test 3
//
//  Created by Lukas Tenbrink on 25.12.20.
//

import AppKit

class DocumentController: NSDocumentController {
    override func makeUntitledDocument(ofType typeName: String) throws -> NSDocument {
        let doc = LibraryDocument(settings: LibrarySettingsLevel())

        let defaultPlaylistsModel = [
            TransientPlaylist(.playlists, attributes: .unsafe([
                .title: "Playlists"
            ]))
        ]
        let (_, playlists) = Library.convert(
            DirectLibrary(allPlaylists: defaultPlaylistsModel),
            context: doc.managedObjectContext!
        )
        doc.settings.defaultPlaylist = playlists[0].uuid
        
        /// All initial object creation should NOT be undoable.
        doc.undoManager?.removeAllActions()
        
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
