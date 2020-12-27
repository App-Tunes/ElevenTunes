//
//  M3UPlaylist+CoreDataClass.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 25.12.20.
//
//

import Foundation
import CoreData
import SwiftUI
import Combine

public class M3UPlaylist: RemotePlaylist {
    var url: URL
    
    init(_ url: URL) {
        self.url = url
        super.init()
    }
    
    static func create(fromURL url: URL) throws -> M3UPlaylist {
        // TODO Only if it's really an M3U
        return M3UPlaylist(url)
    }

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

    public override var icon: Image { Image(systemName: "doc.text.fill") }
}

extension M3UPlaylist {
    enum CodingKeys: String, CodingKey {
      case url
    }
}
