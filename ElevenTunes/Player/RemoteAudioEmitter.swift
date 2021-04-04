//
//  RemoteAudioEmitter.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 20.12.20.
//

import Foundation
import Combine

protocol RemoteAudioEndpoint: AnyObject {
    var delegate: RemoteAudioEndpointDelegate? { get set }
    
    var duration: TimeInterval? { get }

    func start(at time: TimeInterval)
    func seek(to time: TimeInterval)
    func stop()
}

protocol ActiveStateQueryingAudioEndpoint: RemoteAudioEndpoint {
    func queryState()
}

protocol RemoteAudioEndpointDelegate: AnyObject {
    func endpointDidStop(_ endpoint: RemoteAudioEndpoint)
    func endpointSwitchedFocus(_ endpoint: RemoteAudioEndpoint, state: PlayerState?, at date: Date?)
    func endpoint(_ endpoint: RemoteAudioEndpoint, updatedState state: PlayerState, at date: Date?)
}

class RemoteAudioEmitter: AudioTrack {
    static let queryTime: TimeInterval = 10
    
    weak var delegate: AudioTrackDelegate?
    let endpoint: RemoteAudioEndpoint
        
    var lastStartTime: TimeInterval = 0
    var lastStartDate: Date? = nil
    
    var endTimer: Timer?
    
    var stateQueryTimer: Timer? = nil
    var clientStateDate: Date = Date()

    init(_ endpoint: RemoteAudioEndpoint) {
        self.endpoint = endpoint
        self.endpoint.delegate = self
        
        if let endpoint = endpoint as? ActiveStateQueryingAudioEndpoint {
            stateQueryTimer = Timer(timeInterval: Self.queryTime, repeats: true, block: { _ in
                endpoint.queryState()
            })
            RunLoop.main.add(stateQueryTimer!, forMode: .default)
        }
    }
    
    var currentTime: TimeInterval? {
        lastStartTime + (lastStartDate.map(Date().timeIntervalSince) ?? 0)
    }
	
	var volume: Double = 1 // TODO Direct to player
	
    var isPlaying: Bool {
        lastStartDate != nil
    }
    
    var duration: TimeInterval? { endpoint.duration }
    
    func move(to time: TimeInterval) throws {
        lastStartTime = time

        if lastStartDate != nil {
            // Is Playing; restart at the time
            start()
        }
        else {
            delegate?.emitterUpdatedState(self)
            clientStateDate = Date()
            endpoint.seek(to: time)
        }
    }
	
	func move(by time: TimeInterval) throws {
		try currentTime.map { try move(to: $0 + time) }
	}
    
    func start() {
        endpoint.start(at: lastStartTime)
        
        lastStartDate = Date()
        clientStateDate = Date()

        endTimer?.invalidate()
        if let timeLeft = endpoint.duration.map({ $0 - lastStartTime }) {
            endTimer = Timer.scheduledTimer(withTimeInterval: timeLeft, repeats: false) { [unowned self] _ in
                self.delegate?.emitterDidStop(self)
            }
        }
        else {
            endTimer = nil
        }
        
        delegate?.emitterUpdatedState(self)
    }
    
    func stop() {
        endpoint.stop()
        
        clientStateDate = Date()

        if let lastStartDate = lastStartDate {
            lastStartTime += Date().timeIntervalSince(lastStartDate)
        }
        lastStartDate = nil
        endTimer?.invalidate()
        endTimer = nil
        
        delegate?.emitterUpdatedState(self)
    }
}

extension RemoteAudioEmitter: RemoteAudioEndpointDelegate {
    func endpointDidStop(_ endpoint: RemoteAudioEndpoint) {
        delegate?.emitterDidStop(self)
    }
    
    func endpointSwitchedFocus(_ endpoint: RemoteAudioEndpoint, state: PlayerState?, at date: Date?) {
        guard let lastStartDate = lastStartDate else {
            // Who cares, we're paused
            return
        }
        
        // Stop playing by pausing, TODO Emit an error message too
        // Best guess at stop time
        lastStartTime += max(0, Date().timeIntervalSince(lastStartDate) - Self.queryTime)
        self.lastStartDate = nil

        delegate?.emitterUpdatedState(self)
    }
    
    func endpoint(_ endpoint: RemoteAudioEndpoint, updatedState state: PlayerState, at date: Date?) {
        if let date = date, date < clientStateDate {
            // This info is outdated
            return
        }
        
        if let time = state.currentTime {
            lastStartTime = time
            lastStartDate = state.isPlaying ? Date() : nil
        }
        else {
            if let lastStartDate = lastStartDate {
                lastStartTime += Date().timeIntervalSince(lastStartDate)
            }
            lastStartDate = state.isPlaying ? Date() : nil
        }
        
        delegate?.emitterUpdatedState(self)
    }
}
