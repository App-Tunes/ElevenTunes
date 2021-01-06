//
//  AppDelegate.swift
//  Test 3
//
//  Created by Lukas Tenbrink on 24.12.20.
//

import Cocoa
import SwiftUI
import Combine

class GlobalSettingsLevel: SettingsLevel {
    static var instance: SettingsLevel { _instance }
    static var _instance: SettingsLevel!
    
    init(spotify: Spotify) {
        self.spotify = spotify
    }
    
    var spotify: Spotify
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

        GlobalSettingsLevel._instance = GlobalSettingsLevel(spotify: spotify)

        let settingsView = SettingsView().environment(\.settingsLevel, GlobalSettingsLevel.instance)
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

            let interpreter = ContentInterpreter.createDefault(settings: doc.settings)
            interpreter.interpret(urls: urls)?
                .map {
                    ContentInterpreter.library(fromContents: $0, name: "New Document")
                }
                .sink(receiveCompletion: { result in
                    switch result {
                    case .finished:
                        DispatchQueue.main.async {
                            doc.makeWindowControllers()
                            doc.showWindows()
                            documentController.addDocument(doc)
                        }
                    case .failure(let error):
                        // Document will deallocate
                        appLogger.error("Error interpreting urls: \(error)")
                    }
                }) { library in
                    // TODO If import fails, wat do?
                    _ = doc.import(library)
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

