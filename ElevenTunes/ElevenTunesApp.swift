//
//  ElevenTunesApp.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 15.12.20.
//

import SwiftUI

@main
struct ElevenTunesApp: App {
    var body: some Scene {
        DocumentGroup(newDocument: ElevenTunesDocument()) { file in
            ContentView(document: file.$document)
        }
    }
}
