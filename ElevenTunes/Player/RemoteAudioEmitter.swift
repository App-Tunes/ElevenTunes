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
    func endpoint(_ endpoint: RemoteAudioEndpoint, updatedState state: PlayerState, at date: Date?)
}

class RemoteAudioEmitter: AnyAudioEmitter {
    weak var delegate: AudioEmitterDelegate?
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
            stateQueryTimer = Timer(timeInterval: 10, repeats: true, block: { _ in
                endpoint.queryState()
            })
            RunLoop.main.add(stateQueryTimer!, forMode: .default)
        }
    }
    
    var currentTime: TimeInterval? {
        lastStartTime + (lastStartDate.map(Date().timeIntervalSince) ?? 0)
    }
    
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
    
    func endpoint(_ endpoint: RemoteAudioEndpoint, updatedState state: PlayerState, at date: Date?) {
        if let date = date, date < clientStateDate {
            // This info is outdated
            return
        }
        
        // if nil, we are a radio-like thing: time is not important.
        // we may reuse our known time
        lastStartTime = state.currentTime ?? lastStartTime
        lastStartDate = state.isPlaying ? Date() : nil
        
        delegate?.emitterUpdatedState(self)
    }
}
