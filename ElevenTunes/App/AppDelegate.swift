//
//  AppDelegate.swift
//  Test 3
//
//  Created by Lukas Tenbrink on 24.12.20.
//

import Cocoa
import SwiftUI
import Combine

struct GlobalSettingsLevel: SettingsLevel {
    var spotify: Spotify?
}

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
        
        let settingsView = SettingsView().environment(\.settingsLevel, GlobalSettingsLevel(spotify: spotify))
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

        let documentController = NSDocumentController.shared
        
        do {
            let doc = try documentController.makeUntitledDocument(ofType: "library")
                as! LibraryDocument
            let library = doc.library

            library.interpreter.interpret(urls: urls)?
                .map {
                    ContentInterpreter.library(fromContents: $0, name: "New Document")
                }
                .sink(receiveCompletion: { result in
                    switch result {
                    case .finished:
                        doc.makeWindowControllers()
                        doc.showWindows()
                        documentController.addDocument(doc)
                    case .failure(let error):
                        // Document will deallocate
                        appLogger.error("Error interpreting urls: \(error)")
                    }
                }) { library in
                    doc.library.import(library: library)
                }
                .store(in: &cancellables)
        }
        catch let error {
            appLogger.error("Error creating new document: \(error)")
        }
    }

    @IBAction func showSettings(_ sender: AnyObject?) {
        settingsWC.window?.makeKeyAndOrderFront(sender)
    }
}

