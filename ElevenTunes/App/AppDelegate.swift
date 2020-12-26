//
//  AppDelegate.swift
//  Test 3
//
//  Created by Lukas Tenbrink on 24.12.20.
//

import Cocoa
import SwiftUI
import Combine

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    let spotify: Spotify

    let settingsWC: SettingsWindowController
    
    var cancellables = Set<AnyCancellable>()
    
    override init() {
        ValueTransformer.setValueTransformer(PlaylistBackendTransformer(), forName: .playlistBackendName)
        ValueTransformer.setValueTransformer(TrackBackendTransformer(), forName: .trackBackendName)

        let spotify = Spotify()
        self.spotify = spotify
        
        let settingsView = SettingsView().environment(\.spotify, spotify)
        self.settingsWC = .init(content: AnyView(settingsView))
    }
    
    static var shared: AppDelegate {
        NSApp.delegate as! Self
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        var urls = urls

        urls = urls.filter { !spotify.handleURL($0) }

        // TODO 
//        interpreter.interpret(urls: urls)?
//            .map {
//                ContentInterpreter.library(fromContents: $0, name: "New Document")
//            }
//            .sink(receiveCompletion: appLogErrors) { library in
//                let doc = LibraryDocument()
//                doc.library.import(library: library)
//                NSDocumentController.shared.addDocument(doc)
//            }
//            .store(in: &cancellables)
    }

    @IBAction func showSettings(_ sender: AnyObject?) {
        settingsWC.window?.makeKeyAndOrderFront(sender)
    }
}

