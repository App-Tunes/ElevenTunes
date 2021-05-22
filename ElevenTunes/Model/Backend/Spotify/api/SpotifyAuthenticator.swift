//
//  Spotify.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 19.12.20.
//

import Foundation
import Combine
import SwiftUI
import SpotifyWebAPI

import KeychainAccess

/**
 A helper class that wraps around an instance of `SpotifyAPI`
 and provides convenience methods for authorizing your application.
 
 Its most important role is to handle changes to the authorzation
 information and save them to persistent storage in the keychain.
 */
final class SpotifyAuthenticator: ObservableObject {    
    /// A cryptographically-secure random string used to ensure
    /// than an incoming redirect from Spotify was the result of a request
    /// made by this app, and not an attacker. **This value is regenerated**
    /// **after each authorization process completes.**
    var authorizationState = String.randomURLSafe(length: 128)
 
    /**
     Whether or not the application has been authorized. If `true`,
     then you can begin making requests to the Spotify web API
     using the `api` property of this class, which contains an instance
     of `SpotifyAPI`.
     
     When `false`, `LoginView` is presented, which prompts the user to
     login. When this is set to `true`, `LoginView` is dismissed.
     
     This property provides a convenient way for the user interface
     to be updated based on whether the user has logged in with their
     Spotify account yet. For example, you could use this property disable
     UI elements that require the user to be logged in.
     
     This property is updated by `handleChangesToAuthorizationManager()`,
     which is called every time the authorization information changes,
     and `removeAuthorizationManagerFromKeychain()`, which is called
     everytime `SpotifyAPI.authorizationManager.deauthorize()` is called.
     */
    @Published var isAuthorized = false

    /// If `true`, then the app is retrieving access and refresh tokens.
    /// Used by `LoginView` to present an activity indicator.
    @Published var isRetrievingTokens = false
    
    /// The keychain to store the authorization information in.
     let keychain = Keychain(service: "ivorius.ElevenTunes")
    
    /// An instance of `SpotifyAPI` that you use to make requests to
    /// the Spotify web API.
    let api: SpotifyAPI<AuthorizationCodeFlowManager>
    let authManagerKey: String
    let loginCallbackURL: URL
    
    let scopes: Set<Scope>
    var authorizeViewer: (URL) -> Void

    var cancellables: Set<AnyCancellable> = []
    
    init(
        api: SpotifyAPI<AuthorizationCodeFlowManager>,
        authManagerKey: String,
        loginCallbackURL: URL,
        scopes: Set<Scope>,
        authorizeViewer: @escaping (URL) -> Void
    ) {
        self.api = api
        self.authManagerKey = authManagerKey
        self.loginCallbackURL = loginCallbackURL
        self.scopes = scopes
        self.authorizeViewer = authorizeViewer
        
        // Configure the loggers.
        
        // MARK: Important: Subscribe to `authorizationManagerDidChange` BEFORE
        // MARK: retrieving `authorizationManager` from persistent storage
        self.api.authorizationManagerDidChange
            // We must receive on the main thread because we are
            // updating the @Published `isAuthorized` property.
            .receive(on: RunLoop.main)
            .sink(receiveValue: handleChangesToAuthorizationManager)
            .store(in: &cancellables)
        
        self.api.authorizationManagerDidDeauthorize
            .receive(on: RunLoop.main)
            .sink(receiveValue: removeAuthorizationManagerFromKeychain)
            .store(in: &cancellables)
        
        // Check to see if the authorization information is saved in
        // the keychain.
        if let authManagerData = keychain[data: authManagerKey] {
            do {
                // Try to decode the data.
                let authorizationManager = try JSONDecoder().decode(
                    AuthorizationCodeFlowManager.self,
                    from: authManagerData
                )
                print("found authorization information in keychain")

                /*
                 This assignment causes `authorizationManagerDidChange`
                 to emit a signal, meaning that
                 `handleChangesToAuthorizationManager()` will be called.

                 Note that if you had subscribed to
                 `authorizationManagerDidChange` after this line,
                 then `handleChangesToAuthorizationManager()` would not
                 have been called and the @Published `isAuthorized` property
                 would not have been properly updated.

                 We do not need to update `isAuthorized` here because it
                 is already done in `handleChangesToAuthorizationManager()`.
                 */
                self.api.authorizationManager = authorizationManager

            } catch {
                print("could not decode authorizationManager from data:\n\(error)")
            }
        }
        else {
            print("did NOT find authorization information in keychain")
        }
        
    }
    
    /**
     A convenience method that creates the authorization URL and opens it
     in the browser.
     
     You could also configure it to accept parameters for the authorization
     scopes.
     
     This is called when the user taps the "Log in with Spotify" button
     in `LoginView`.
     */
    func authorize() {
        let url = api.authorizationManager.makeAuthorizationURL(
            redirectURI: loginCallbackURL,
            showDialog: true,
            // This same value **MUST** be provided for the state parameter of
            // `authorizationManager.requestAccessAndRefreshTokens(redirectURIWithQuery:state:)`.
            // Otherwise, an error will be thrown.
            state: authorizationState,
            scopes: scopes
        )!
        
        // You can open the URL however you like. For example, you could open
        // it in a web view instead of the browser.
        // See https://developer.apple.com/documentation/webkit/wkwebview
        authorizeViewer(url)
    }
    
    /**
     Saves changes to `api.authorizationManager` to the keychain.
     
     This method is called every time the authorization information changes. For
     example, when the access token gets automatically refreshed, (it expires after
     an hour) this method will be called.
     
     It will also be called after the access and refresh tokens are retrieved using
     `requestAccessAndRefreshTokens(redirectURIWithQuery:state:)`.
     
     Read the full documentation for [SpotifyAPI.authorizationManagerDidChange][1].
     
     [1]: https://peter-schorn.github.io/SpotifyAPI/Classes/SpotifyAPI.html#/s:13SpotifyWebAPI0aC0C29authorizationManagerDidChange7Combine18PassthroughSubjectCyyts5NeverOGvp
     */
    func handleChangesToAuthorizationManager() {
		self.isAuthorized = self.api.authorizationManager.isAuthorized()
			&& self.api.authorizationManager.scopes.isSuperset(of: scopes)

        print(
            "Spotify.handleChangesToAuthorizationManager: isAuthorized:",
            self.isAuthorized
        )

        do {
            // Encode the authorization information to data.
            let authManagerData = try JSONEncoder().encode(
                self.api.authorizationManager
            )

            // Save the data to the keychain.
            keychain[data: authManagerKey] = authManagerData
            print("did save authorization manager to keychain")

        } catch {
            print(
                "couldn't encode authorizationManager for storage " +
                "in keychain:\n\(error)"
            )
        }
        
    }
 
    /**
     Removes `api.authorizationManager` from the keychain.
     
     This method is called everytime `api.authorizationManager.deauthorize` is
     called.
     */
    func removeAuthorizationManagerFromKeychain() {
        self.isAuthorized = false

        do {
            /*
             Remove the authorization information from the keychain.

             If you don't do this, then the authorization information
             that you just removed from memory by calling `deauthorize()`
             will be retrieved again from persistent storage after this
             app is quit and relaunched.
             */
            try keychain.remove(authManagerKey)
            print("did remove authorization manager from keychain")

        } catch {
            print(
                "couldn't remove authorization manager " +
                "from keychain: \(error)"
            )
        }
    }
    
    func handleURL(_ url: URL) -> Bool {
        // **Always** validate URLs; they offer a potential attack
        // vector into your app.
        guard url.scheme == loginCallbackURL.scheme else {
            return false
        }

        // This property is used to display an activity indicator in
        // `LoginView` indicating that the access and refresh tokens
        // are being retrieved.
        isRetrievingTokens = true
        
        // Complete the authorization process by requesting the
        // access and refresh tokens.
        api.authorizationManager.requestAccessAndRefreshTokens(
            redirectURIWithQuery: url,
            // This value must be the same as the one used to create the
            // authorization URL. Otherwise, an error will be thrown.
            state: authorizationState
        )
        .receive(on: RunLoop.main)
        .sink(receiveCompletion: { completion in
            // Whether the request succeeded or not, we need to remove
            // the activity indicator.
            self.isRetrievingTokens = false
            
            /*
             After the access and refresh tokens are retrieved,
             `SpotifyAPI.authorizationManagerDidChange` will emit a
             signal, causing `handleChangesToAuthorizationManager()` to be
             called, which will dismiss the loginView if the app was
             successfully authorized by setting the
             @Published `Spotify.isAuthorized` property to `true`.
             The only thing we need to do here is handle the error and
             show it to the user if one was received.
             */
            if case .failure(let error) = completion {
                print("couldn't retrieve access and refresh tokens:\n\(error)")
                if let authError = error as? SpotifyAuthorizationError,
                        authError.accessWasDenied {
                    print("Denied")
                }
                else {
                    print("Some Error")
                }
            }
        })
        .store(in: &cancellables)
        
        // MARK: IMPORTANT: generate a new value for the state parameter
        // MARK: after each authorization request. This ensures an incoming
        // MARK: redirect from Spotify was the result of a request made by
        // MARK: this app, and not an attacker.
        authorizationState = String.randomURLSafe(length: 128)
        
        return true
    }
}
