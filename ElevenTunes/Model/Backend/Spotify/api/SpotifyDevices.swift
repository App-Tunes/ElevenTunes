//
//  SpotifyDevices.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 23.12.20.
//

import Foundation
import SpotifyWebAPI
import Combine
import SwiftUI

class SpotifyDevices<Backend: AuthorizationCodeFlowBackend>: ObservableObject {
    let api: SpotifyAPI<AuthorizationCodeFlowBackendManager<Backend>>
    var cancellables = Set<AnyCancellable>()
    
    @Published var rememberAllDevices = true
    @Published var alwaysPlayOnFavorite = true {
        didSet { flushFavorite() }
    }

    @Published var all: [Device] = []
    @Published var online: [Device] = []
    @Published var favorite: Device?

    @Published var selected: Device? {
        // Reset if user unsets a device
        didSet { if favorite != nil && selected == nil { selected = favorite } }
    }

    init(api: SpotifyAPI<AuthorizationCodeFlowBackendManager<Backend>>) {
        self.api = api
        // assign and didSet doesn't work :(
        self.$all.map(\.first).sink { [weak self] favorite in
            self?.favorite = favorite
            self?.flushFavorite()
        }.store(in: &cancellables)
    }
    
    private func flushFavorite() {
        if alwaysPlayOnFavorite && favorite != selected {
            selected = favorite
        }
    }
    
    func query() {
        api.availableDevices()
            .onMain()
            .sink(receiveCompletion: appLogErrors(_:)) { [weak self] devices in
                guard let self = self else { return }
                self.online = devices.filter { !$0.isRestricted }
                self.all = self.online
            }
            .store(in: &cancellables)
    }
    
    func bindIsSelected(_ device: Device) -> Binding<Bool> {
        return Binding {
            self.selected == device
        } set: {
            if $0 {
                self.selected = device
            }
            else if self.selected == device {
                self.selected = nil
            }
        }
    }
}
