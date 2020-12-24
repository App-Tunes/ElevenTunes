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
    static let defaultValue: Spotify? = nil
}

struct InterpreterEnvironmentKey: EnvironmentKey {
    static let defaultValue: ContentInterpreter? = nil
}

extension EnvironmentValues {
    var spotify: Spotify? {
        get { self[SpotifyEnvironmentKey] }
        set { self[SpotifyEnvironmentKey] = newValue }
    }

    var interpreter: ContentInterpreter? {
        get { self[InterpreterEnvironmentKey] }
        set { self[InterpreterEnvironmentKey] = newValue }
    }
}

class AppDelegateAdaptor: NSObject, NSApplicationDelegate {
    var cancellables = Set<AnyCancellable>()

    func application(_ application: NSApplication, open urls: [URL]) {
        var urls = urls
        
        urls = urls.filter { !ElevenTunesApp.shared.spotify.handleURL($0) }
        
        ElevenTunesApp.shared.interpreter.interpret(urls: urls)?
            .map {
                ContentInterpreter.library(fromContents: $0, name: "New Document")
            }
            .sink(receiveCompletion: appLogErrors) { library in
//                let doc = ElevenTunesDocument(playlist: library) as NSDocument
                //.addDocument()
            }
            .store(in: &cancellables)
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
    
    let spotify: Spotify
    let interpreter: ContentInterpreter

    init() {
        let spotify = Spotify()
        self.spotify = spotify
        interpreter = ContentInterpreter.createDefault(spotify: spotify)
        Self.shared = self
    }
    
    var body: some Scene {
        DocumentGroup(newDocument: ElevenTunesDocument(playlist: LibraryMock.directory())) { file in
            ContentView(document: file.$document)
                .onOpenURL { url in
                    appLogger.warning("onOpenURL finally works \(url)!")
                }
                .environment(\.interpreter, interpreter)
                .environment(\.spotify, spotify)
        }
        
        #if os(macOS)
        Settings {
            SettingsView()
                .environment(\.spotify, spotify)
        }
        #endif
    }
}
