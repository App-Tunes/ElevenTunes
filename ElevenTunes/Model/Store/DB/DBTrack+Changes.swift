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

            backend.loadLevel
                .onMain()
                .sink { [unowned self] loadLevel in
                    self._loadLevel = loadLevel
                    self.cachedLoadLevel = loadLevel.rawValue
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
        }
        
        if changes.keys.contains("cachedLoadLevel") {
            _loadLevel = LoadLevel(rawValue: cachedLoadLevel) ?? .none
        }
    }
}
