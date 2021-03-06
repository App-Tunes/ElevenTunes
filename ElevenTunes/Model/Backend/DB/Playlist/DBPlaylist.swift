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

public struct DBPlaylistToken: PlaylistToken {
	enum InterpretationError: Error {
		case invalidID
		case dontExpandMeBro
	}
	
	let uri: URL
	
	public var id: String { uri.absoluteString }
	public var origin: URL? { nil }
	
	public static func understands(_ url: URL) -> Bool {
		print(url)
		return false
	}
	
	public static func create(fromUrl url: URL) -> DBPlaylistToken {
		DBPlaylistToken(uri: url)
	}
	
	public func fetch(fromContext context: NSManagedObjectContext) throws -> DBPlaylist {
		guard let objectID = context.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: uri)
		else {
			throw InterpretationError.invalidID
		}
		
		guard
			let object = try context.existingObject(with: objectID) as? DBPlaylist
		else {
			throw InterpretationError.invalidID
		}
		
		return object
	}
	
	public func expand(_ context: Library) throws -> AnyPlaylist {
		throw InterpretationError.dontExpandMeBro
	}
}
