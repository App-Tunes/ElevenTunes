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
	enum SpotifySetupError {
		case missingInformation
	}
        
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
		
		.streaming,
		.appRemoteControl,

		.playlistReadPrivate,
		.playlistModifyPrivate,
        .playlistModifyPublic,
		.playlistReadCollaborative,

        .userLibraryRead,
        .userLibraryModify,
        .userReadEmail
    ]
    
    let api: SpotifyAPI<AuthorizationCodeFlowBackendManager<AuthorizationCodeFlowProxyBackend>>
    
    let authenticator: SpotifyAuthenticator<AuthorizationCodeFlowProxyBackend>
    let devices: SpotifyDevices<AuthorizationCodeFlowProxyBackend>
    
    var cancellables = Set<AnyCancellable>()
    
    // TODO This is a reference cycle :|
    var artistCaches: [SpotifyArtistToken: SpotifyArtist] = [:]
	var albumCaches: [SpotifyAlbumToken: SpotifyAlbum] = [:]
	var trackCaches: [SpotifyTrackToken: SpotifyTrack] = [:]

	
	init(backend: AuthorizationCodeFlowProxyBackend) {
        let api = SpotifyAPI(authorizationManager: AuthorizationCodeFlowBackendManager(backend: backend))
        
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
