//
//  DBPlaylist+Properties.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 27.12.20.
//

import Foundation

extension DBPlaylist {
	enum AttributeGroup {
		case tracks, children, attributes
	}
	
	static let attributeGroups: SetRelation<PlaylistAttribute, AttributeGroup> = [
		.tracks: [.tracks],
		.children: [.children],
		.attributes: [.title]
	]
	
	static let versionByAttribute: [AttributeGroup: KeyPath<DBPlaylist, PlaylistVersion?>] = [
		.tracks: \Self.tracksVersion,
		.children: \Self.childrenVersion,
		.attributes: \Self.version
	]
	
	static let keypathByAttribute: [PlaylistAttribute: String] = [
		.title: "title",
		.tracks: "tracks",
		.children: "children"
    ]
	
	static let attributeByKeypath: [String: PlaylistAttribute] = Dictionary(uniqueKeysWithValues: keypathByAttribute.map { ($1, $0) })
}
