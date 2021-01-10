//
//  FileTrack+CoreDataClass.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 25.12.20.
//
//

import Foundation

public class FileTrackToken: TrackToken {
    enum CodingKeys: String, CodingKey {
      case url
    }

    public let url: URL
        
    init(_ url: URL) {
        self.url = url
        super.init()
    }
	
	public override var id: String { url.absoluteString }

	override var origin: URL? { url }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        url = try container.decode(URL.self, forKey: .url)
        try super.init(from: decoder)
    }
    
    public override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(url, forKey: .url)
        try super.encode(to: encoder)
    }
}
