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
    @Binding var library: Library
    @State var isImporting: Bool = false

    let player = Player()
    
    init(library: Binding<Library>) {
        self._library = library
    }
    
    var body: some View {
        VSplitView {
            PlayerBarView()
                .frame(maxWidth: .infinity)

            NavigatorView(directory: Playlist(library.mainPlaylist))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .layoutPriority(2)
        }
            .environment(\.player, player)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        ContentView(document: .constant(LibraryD))
//    }
//}
