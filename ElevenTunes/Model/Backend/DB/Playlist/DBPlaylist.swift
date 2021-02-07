//
//  DBPlaylist+CoreDataClass.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 25.01.21.
//
//

import Foundation
import CoreData
import Combine

@objc(DBPlaylist)
public class DBPlaylist: NSManagedObject {
	@objc public enum Representation: Int16 {
		case none, directory, m3u, spotify
	}
		
	@Published var contentTypeP: PlaylistContentType = .hybrid

	@Published public var primaryRepresentationP: Representation = .none
	@Published public var representationsP: [Representation: AnyPlaylistCache] = [:]
	
	public override func awakeFromFetch() { initialSetup() }
	public override func awakeFromInsert() {
		uuid = UUID()
		initialSetup()
	}
	
	func initialSetup() {
		contentTypeP = contentType
		primaryRepresentationP = primaryRepresentation

		representationsP[.directory] = directoryRepresentation
		representationsP[.m3u] = m3uRepresentation
		representationsP[.spotify] = spotifyRepresentation
	}
}

protocol BranchablePlaylist {
	@discardableResult
	func store(in playlist: DBPlaylist) throws -> DBPlaylist.Representation
}
