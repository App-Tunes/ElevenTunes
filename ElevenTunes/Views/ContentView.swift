//
//  ContentView.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 15.12.20.
//

import SwiftUI

struct PlayerEnvironmentKey: EnvironmentKey {
    static let defaultValue: Player = Player()
}

extension EnvironmentValues {
    var player: Player {
        get { self[PlayerEnvironmentKey] }
        set { self[PlayerEnvironmentKey] = newValue }
    }
}

struct ContentView: View {
    @Binding var document: ElevenTunesDocument
    @State var isImporting: Bool = false

    let player = Player()
    
    init(document: Binding<ElevenTunesDocument>) {
        self._document = document
    }
    
    var body: some View {
        VSplitView {
            PlayerBarView()
                .frame(maxWidth: .infinity)

            NavigatorView(directory: document.playlist)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .layoutPriority(2)
        }
            .environment(\.player, player)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(document: .constant(ElevenTunesDocument(playlist: LibraryMock.directory())))
    }
}
