//
//  PersistentTrack.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 27.12.20.
//

import Foundation
import Combine
import SwiftUI

public class TrackToken: NSObject, Codable {
    public var id: String { fatalError() }
    
	var origin: URL? { nil }

    func expand(_ context: Library) -> AnyTrack { fatalError() }
    
    // NSObject gedöns
    
    public override var hash: Int { id.hash }
    
    public override func isEqual(_ other: Any?) -> Bool {
        guard let other = other as? TrackToken else { return false }
        return self.id == other.id
    }
}

extension TrackToken: Identifiable { }
