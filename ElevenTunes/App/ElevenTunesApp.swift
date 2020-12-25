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


//struct ElevenTunesApp: App {
//    // Ewww super hacky
//    //   I'm open to suggestions lol
//    static var shared: ElevenTunesApp!
//
//    @NSApplicationDelegateAdaptor(AppDelegateAdaptor.self) private var appDelegate
//
//    let spotify: Spotify
//    let interpreter: ContentInterpreter
//
//    init() {
//        let spotify = Spotify()
//        self.spotify = spotify
//        interpreter = ContentInterpreter.createDefault(spotify: spotify)
//        Self.shared = self
//    }
//
//    func documentView(_ document: Binding<ElevenTunesDocument>) -> some View {
//        ContentView(document: document)
//            .onOpenURL { url in
//                appLogger.warning("onOpenURL finally works \(url)!")
//            }
//            .environment(\.interpreter, interpreter)
//            .environment(\.spotify, spotify)
//    }
//
//    var body: some Scene {
//        DocumentGroup(newDocument: ElevenTunesDocument(playlist: LibraryMock.directory())) { file in
//            documentView(file.$document)
//        }
//
//        #if os(macOS)
//        Settings {
//            SettingsView()
//                .environment(\.spotify, spotify)
//        }
//        #endif
//    }
//}
