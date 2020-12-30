//
//  PersistentPlaylist.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 27.12.20.
//

import Foundation
import Combine
import SwiftUI

public class PlaylistToken: NSObject, Codable {
    public var id: String { fatalError() }

    func expand(_ context: Library) -> AnyPublisher<AnyPlaylist, Never> { fatalError() }

    // NSObject gedöns
    
    public override var hash: Int { id.hash }
    
    public override func isEqual(_ other: Any?) -> Bool {
        guard let other = other as? PlaylistToken else { return false }
        return self.id == other.id
    }
}

extension PlaylistToken: Identifiable {}
