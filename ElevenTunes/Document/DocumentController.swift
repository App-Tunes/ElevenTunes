//
//  DocumentController.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 25.12.20.
//

import AppKit

class DocumentController: NSDocumentController {
    override func makeUntitledDocument(ofType typeName: String) throws -> NSDocument {
		let doc = LibraryDocument(settings: LibrarySettingsLevel())

		guard
			let model = doc.managedObjectContext!.persistentStoreCoordinator?.managedObjectModel,
			let playlistModel = model.entitiesByName["DBPlaylist"]
		else {
			fatalError("Failed to find model in MOC")
		}

		let defaultPlaylist = DBPlaylist(entity: playlistModel, insertInto: doc.managedObjectContext!)
		defaultPlaylist.title = "Playlists"
		defaultPlaylist.contentType = .playlists
		defaultPlaylist.initialSetup()
			
		doc.settings.defaultPlaylist = defaultPlaylist.uuid
        
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
