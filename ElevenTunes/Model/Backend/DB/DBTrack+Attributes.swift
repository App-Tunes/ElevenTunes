//
//  DBTrack+Attributes.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 27.12.20.
//

import Foundation

extension DBTrack {
	enum AttributeGroup {
		case info
		// TODO Analysis Group
	}
	
	static let attributeGroups: SetRelation<TrackAttribute, AttributeGroup> = [
		.info: [.title]
	]
	
	static let keypathByAttribute: [TrackAttribute: String] = [
		.title: "title"
	]
	
	static let attributeByKeypath: [String: TrackAttribute] = Dictionary(uniqueKeysWithValues: keypathByAttribute.map { ($1, $0) })
}
