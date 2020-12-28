//
//  DBTrack+Changes.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 27.12.20.
//

import Foundation

extension DBTrack {
    func refreshObservation() {
        backendObservers = []
        if let backend = backend {
            backend.attributes
                .onMain()
                .sink { [unowned self] attributes in
                    merge(attributes: attributes)
                }
                .store(in: &backendObservers)

            backend.cacheMask
                .onMain()
                .sink { [unowned self] cacheMask in
                    self.backendCacheMask |= cacheMask.rawValue
                }
                .store(in: &backendObservers)
        }
    }
}

extension DBTrack: SelfChangeWatcher {
    func onSelfChange() {
        let changes = changedValues()
        
        if !DBTrack.attributeProperties.isDisjoint(with: changes.keys) {
            _attributes = cachedAttributes
        }
        
        if changes.keys.contains("backend") {
            refreshObservation()
            if backend != nil {
                // Invalidate stuff we stored for the backend
                if backendCacheMask != 0 { backendCacheMask = 0 }
                // Attributes will be either overriden by new playlist, or kept
            }
        }

        if changes.keys.contains("backendCacheMask") {
            _cacheMask = TrackContentMask(rawValue: backendCacheMask)
        }
    }
}
