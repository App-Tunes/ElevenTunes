//
//  DBPlaylist+CoreDataClass.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 26.12.20.
//
//

import Foundation
import CoreData

@objc(DBPlaylist)
public class DBPlaylist: NSManagedObject {
    @Published var backendP: PlaylistToken? = nil
    @Published var isIndexedP: Bool = false
    @Published var contentTypeP: PlaylistContentType = .hybrid

	let attributes: VolatileAttributes<PlaylistAttribute, PlaylistVersion> = .init()
    
    public override func awakeFromFetch() { initialSetup() }
    public override func awakeFromInsert() {
        uuid = UUID()
        initialSetup()
    }
    
    func initialSetup() {
        backendP = backend
        isIndexedP = indexed
        contentTypeP = contentType

		var update = [PlaylistAttribute: Any?]()
		var empty: Set<PlaylistAttribute> = []
		for (attributeKey, attribute) in DBPlaylist.attributeByKeypath {
			// TODO Can we make this type-safe?
			if let value = value(forKey: attributeKey) {
				update[attribute] = value
			}
			else {
				empty.insert(attribute)
			}
		}
		let state: PlaylistAttributes.State = .version(version ?? "")
		attributes.update(.unsafe(update, state: state))
    }
}
