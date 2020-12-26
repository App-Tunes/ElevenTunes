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
    var cancellables = Set<AnyCancellable>()
    
    public var id: String { objectID.description }
    
    public var icon: Image {
        backend?.icon ?? Image(systemName: "music.note.list")
    }
    
    @Published private var _anyTracks: [AnyTrack] = []
    public var anyTracks: AnyPublisher<[AnyTrack], Never> {
        $_anyTracks.eraseToAnyPublisher()
    }
    
    @Published private var _anyChildren: [AnyPlaylist] = []
    public var anyChildren: AnyPublisher<[AnyPlaylist], Never> {
        $_anyChildren.eraseToAnyPublisher()
    }
    
    @Published private var _loadLevel: LoadLevel = .none
    public var loadLevel: AnyPublisher<LoadLevel, Never> {
        $_loadLevel.eraseToAnyPublisher()
    }
    
    public var attributes: AnyPublisher<TypedDict<PlaylistAttribute>, Never> {
        backend?.attributes ?? Just(.init()).eraseToAnyPublisher()  // TODO
    }
    
    private func refreshObservation() {
        guard let context = managedObjectContext else { return }

        cancellables = []
        if let backend = backend {
            backend.tracks.sink { [unowned self] tracks in
                if indexed {
                    let old = self.tracks
                    let (dbTracks, _) = Library.convert(DirectLibrary(allTracks: tracks), context: context)
                    self.tracks = NSOrderedSet(array: dbTracks)
                    Library.prune(tracks: old.array as! [DBTrack], context: context)
                }
                
                _anyTracks = tracks
            }.store(in: &cancellables)
            
            backend.children.sink { [unowned self] children in
                if indexed {
                    let old = self.children
                    let (_, dbPlaylists) = Library.convert(DirectLibrary(allPlaylists: children), context: context)
                    self.children = NSOrderedSet(array: dbPlaylists)
                    Library.prune(playlists: old.array as! [DBPlaylist], context: context)
                }
                
                _anyChildren = children
            }.store(in: &cancellables)
            
            backend.loadLevel.sink { [unowned self] loadLevel in
                self._loadLevel = loadLevel
                self.cachedLoadLevel = loadLevel.rawValue
            }.store(in: &cancellables)
        }
        else {
            do {
                let tracksFetchRequest = DBTrack.createFetchRequest()
                tracksFetchRequest.predicate = NSPredicate(format: "ALL references = %@", self)
                CDPublisher(request: tracksFetchRequest, context: context)
                    .sink(receiveCompletion: appLogErrors) {
                        [weak self] in self?._anyTracks = $0
                    }
                    .store(in: &cancellables)

                let childrenFetchRequest = Self.createFetchRequest()
                childrenFetchRequest.predicate = NSPredicate(format: "ALL parent = %@", self)
                CDPublisher(request: childrenFetchRequest, context: context)
                    .sink(receiveCompletion: appLogErrors) {
                        [weak self] in self?._anyChildren = $0
                    }
                    .store(in: &cancellables)
            }
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
        guard level > currentLoadLevel else {
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
