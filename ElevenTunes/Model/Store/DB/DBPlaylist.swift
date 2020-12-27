//
//  DBPlaylist+CoreDataClass.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 26.12.20.
//
//

import Foundation
import CoreData
import Combine
import SwiftUI

@objc(DBPlaylist)
public class DBPlaylist: NSManagedObject, AnyPlaylist {
    var observers = Set<AnyCancellable>()
    var backendObservers = Set<AnyCancellable>()

    public var id: String { objectID.description }
    
    public var icon: Image {
        backend?.icon ?? Image(systemName: "music.note.list")
    }
    
    @Published var _anyTracks: [AnyTrack] = []
    public var anyTracks: AnyPublisher<[AnyTrack], Never> {
        $_anyTracks.eraseToAnyPublisher()
    }
    
    @Published var _anyChildren: [AnyPlaylist] = []
    public var anyChildren: AnyPublisher<[AnyPlaylist], Never> {
        $_anyChildren.eraseToAnyPublisher()
    }
    
    @Published var _loadLevel: LoadLevel = .none
    public var loadLevel: AnyPublisher<LoadLevel, Never> {
        $_loadLevel.eraseToAnyPublisher()
    }
    
    @Published var _attributes: TypedDict<PlaylistAttribute> = .init()
    public var attributes: AnyPublisher<TypedDict<PlaylistAttribute>, Never> {
        $_attributes.eraseToAnyPublisher()
    }
    
    func refreshObservation() {
        guard let context = managedObjectContext else { return }
        
        if observers.isEmpty {
            let tracksFetchRequest = DBTrack.createFetchRequest()
            tracksFetchRequest.predicate = NSPredicate(format: "ALL references = %@", self)
            CDPublisher(request: tracksFetchRequest, context: context)
                .sink(receiveCompletion: appLogErrors) {
                    [weak self] in self?._anyTracks = $0
                }
                .store(in: &observers)

            let childrenFetchRequest = Self.createFetchRequest()
            childrenFetchRequest.predicate = NSPredicate(format: "ALL parent = %@", self)
            CDPublisher(request: childrenFetchRequest, context: context)
                .sink(receiveCompletion: appLogErrors) {
                    [weak self] in self?._anyChildren = $0
                }
                .store(in: &observers)
            
            let selfFetchRequest = Self.createFetchRequest()
            selfFetchRequest.predicate = NSPredicate(format: "self = %@", self)
            CDPublisher(request: selfFetchRequest, context: context)
                .sink(receiveCompletion: appLogErrors) { [unowned self] _ in
                    _attributes = cachedAttributes
                    _loadLevel = LoadLevel(rawValue: self.cachedLoadLevel) ?? .none
                    refreshObservation()
                }
                .store(in: &observers)
        }
        
        backendObservers = []
        if let backend = backend {
            backend.tracks
                .onMain()
                .sink { [unowned self] tracks in
                    let oldIDs = self.tracks.map { ($0 as! DBTrack).backendID }
                    if indexed, oldIDs != tracks.map(\.id) {
                        let old = self.tracks
                        let (dbTracks, _) = Library.convert(DirectLibrary(allTracks: tracks), context: context)
                        self.tracks = NSOrderedSet(array: dbTracks)
                        Library.prune(tracks: old.array as! [DBTrack], context: context)
                    }
                    
                    _anyTracks = tracks
                }
                .store(in: &backendObservers)
            
            backend.children
                .onMain()
                .sink { [unowned self] children in
                    let oldIDs = self.children.map { ($0 as! DBPlaylist).backendID }
                    if indexed, oldIDs != children.map(\.id) {
                        let old = self.children
                        let (_, dbPlaylists) = Library.convert(DirectLibrary(allPlaylists: children), context: context)
                        self.children = NSOrderedSet(array: dbPlaylists)
                        Library.prune(playlists: old.array as! [DBPlaylist], context: context)
                    }
                    
                    _anyChildren = children
                }
                .store(in: &backendObservers)

            backend.attributes
                .onMain()
                .sink { [unowned self] attributes in
                    merge(attributes: attributes)
                }
                .store(in: &backendObservers)

            backend.loadLevel.sink { [unowned self] loadLevel in
                self._loadLevel = loadLevel
                self.cachedLoadLevel = loadLevel.rawValue
            }.store(in: &backendObservers)
        }
    }
    
    public override func awakeFromFetch() { refreshObservation() }
    public override func awakeFromInsert() { refreshObservation() }

    @discardableResult
    public func load(atLeast level: LoadLevel, deep: Bool) -> Bool {
        guard level > _loadLevel else {
            return true
        }
        
        guard let backend = backend else {
            // Fetch requests have already set the values
            _loadLevel = .detailed
            return true
        }
        
        let currentLoadLevel = LoadLevel(rawValue: cachedLoadLevel) ?? .none
        if indexed && currentLoadLevel >= level {
            // We can use DB cache! Yay!
            _loadLevel = currentLoadLevel
            return true
        }
        
        return backend.load(atLeast: level, deep: false)
    }

    @discardableResult
    public func add(tracks: [PersistentTrack]) -> Bool {
        if let backend = backend {
            return backend.add(tracks: tracks)
        }
        
        guard let context = managedObjectContext else {
            return false
        }
        
        // We are without backend, aka transient
        let (tracks, _) = Library.convert(DirectLibrary(allTracks: tracks), context: context)
        addToTracks(NSOrderedSet(array: tracks))
        
        return true
    }
    
    @discardableResult
    public func add(children: [PersistentPlaylist]) -> Bool {
        if let backend = backend {
            return backend.add(children: children)
        }
        
        guard let context = managedObjectContext else {
            return false
        }

        // We are without backend, aka transient
        let (_, playlists) = Library.convert(DirectLibrary(allPlaylists: children), context: context)
        addToChildren(NSOrderedSet(array: playlists))
        
        return true
    }
}
