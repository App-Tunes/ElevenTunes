//
//  ETSpotify.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 20.12.20.
//

import Foundation
import SpotifyWebAPI
import AppKit
import Combine

class Spotify {
    private static let clientId: String = {
        if let clientId = ProcessInfo.processInfo
                .environment["spotify_client_id"] {
            return clientId
        }
        fatalError("Could not find 'client_id' in environment variables")
    }()
    
    private static let clientSecret: String = {
        if let clientSecret = ProcessInfo.processInfo
                .environment["spotify_client_secret"] {
            return clientSecret
        }
        fatalError("Could not find 'client_secret' in environment variables")
    }()
    
    /// The key in the keychain that is used to store the authorization
    /// information: "authorizationManager".
    static let authorizationManagerKey = "authorizationManager"
    
    /// The URL that Spotify will redirect to after the user either
    /// authorizes or denies authorization for your application.
    static let loginCallbackURL = URL(
        string: "eleventunes://spotify-login-callback"
    )!
    
    static let scopes: Set<Scope> = [
        .userReadPlaybackState,
        .userModifyPlaybackState,
        .playlistModifyPrivate,
        .playlistModifyPublic,
        .userLibraryRead,
        .userLibraryModify,
        .userReadEmail
    ]
    
    let api: SpotifyAPI<AuthorizationCodeFlowManager>
    
    let authenticator: SpotifyAuthenticator
    let devices: SpotifyDevices
    
    var cancellables = Set<AnyCancellable>()
    
    // TODO This is a reference cycle :|
    var artistCaches: [SpotifyArtistToken: SpotifyArtist] = [:]
    var albumCaches: [SpotifyAlbumToken: SpotifyAlbum] = [:]

    init() {
        let api = SpotifyAPI(
            authorizationManager: AuthorizationCodeFlowManager(
                clientId: Self.clientId, clientSecret: Self.clientSecret
            )
        )
        
        self.api = api
        
        authenticator = SpotifyAuthenticator(
            api: api,
            authManagerKey: "spotify-authorization",
            loginCallbackURL: Self.loginCallbackURL,
            scopes: Self.scopes,
            // TODO Use WKWebView
            authorizeViewer: { url in
                NSWorkspace.shared.open(url)
            }
        )
        
        let devices = SpotifyDevices(api: api)
        self.devices = devices
        
        authenticator.$isAuthorized.sink { isAuthorized in
            if isAuthorized {
                devices.query()
            }
        }
        .store(in: &cancellables)
    }
    
    func handleURL(_ url: URL) -> Bool {
        return authenticator.handleURL(url)
    }
}
