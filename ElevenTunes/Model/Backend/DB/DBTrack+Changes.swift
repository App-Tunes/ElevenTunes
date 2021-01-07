//
//  DBTrack+Changes.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 27.12.20.
//

import Foundation

extension DBTrack: SelfChangeWatcher {
    func onSelfChange() {
        let changes = changedValues()
        
        if !DBTrack.attributeProperties.isDisjoint(with: changes.keys) {
            attributesP = cachedAttributes
        }
        
        if changes.keys.contains("backend"), backendP != backend {
            if backend != nil {
                // Invalidate stuff we stored for the backend
                if backendCacheMask != 0 { backendCacheMask = 0 }
                // Attributes will be either overriden by new playlist, or kept
            }
            
            backendP = backend
            backendID = backend?.id ?? ""
        }

        if changes.keys.contains("backendCacheMask") {
            cacheMaskP ?= TrackContentMask(rawValue: backendCacheMask)
        }
    }
}
