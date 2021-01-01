//
//  ContentView.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 15.12.20.
//

import SwiftUI

struct PlayerEnvironmentKey: EnvironmentKey {
    static let defaultValue: Player? = nil
}

extension EnvironmentValues {
    var player: Player? {
        get { self[PlayerEnvironmentKey] }
        set { self[PlayerEnvironmentKey] = newValue }
    }
}

struct ContentView: View {
    @State var isImporting: Bool = false
    
    @Environment(\.library) var library: Library!
    
    var body: some View {
        VSplitView {
            PlayerBarView()
                .frame(maxWidth: .infinity)

            NavigatorView(directory: Playlist(library.mainPlaylist))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .layoutPriority(2)
        }
            .preferredColorScheme(.dark)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        ContentView(document: .constant(LibraryD))
//    }
//}
