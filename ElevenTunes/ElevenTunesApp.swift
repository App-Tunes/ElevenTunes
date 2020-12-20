//
//  ElevenTunesApp.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 15.12.20.
//

import SwiftUI
import Combine
import Logging
import SpotifyWebAPI

struct SpotifyEnvironmentKey: EnvironmentKey {
    static let defaultValue: Spotify = Spotify()
}

extension EnvironmentValues {
    var spotify: Spotify {
        get { self[SpotifyEnvironmentKey] }
        set { self[SpotifyEnvironmentKey] = newValue }
    }
}

class AppDelegateAdaptor: NSObject, NSApplicationDelegate {
    func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls {
            ElevenTunesApp.shared.spotify.handleURL(url)
        }
    }
}

let appLogger = Logger(label: "ElevenTunes")

func appLogErrors(_ completion: Subscribers.Completion<Error>) {
    switch completion {
    case .failure(let error):
        appLogger.error("Error: \(error)")
    default:
        return
    }
}


@main
struct ElevenTunesApp: App {
    // Ewww super hacky
    //   I'm open to suggestions lol
    static var shared: ElevenTunesApp!
    
    @NSApplicationDelegateAdaptor(AppDelegateAdaptor.self) private var appDelegate
    
    @Environment(\.spotify) var spotify: Spotify

    init() {
        Self.shared = self
    }
    
    var body: some Scene {
        DocumentGroup(newDocument: ElevenTunesDocument()) { file in
            ContentView(document: file.$document)
                .onOpenURL { url in
                    appLogger.warning("onOpenURL finally works \(url)!")
                }
        }
    }
}
