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

    @State var selection = Set<Playlist>()

    var body: some View {
        
        HSplitView {
            ZStack(alignment: .top) {
                List(selection: $selection) {
                    NavigatorView(directory: Playlist(library.mainPlaylist))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }

                VisualEffectView(material: .sidebar, blendingMode: .behindWindow, emphasized: false)
                    .frame(height: 50)
                    .edgesIgnoringSafeArea(.top)
            }
            // TODO hugging / compression resistance:
            // setting min height always compressed down to min height :<
            .frame(minWidth: 250, idealWidth: 250, maxWidth: 400)

            VSplitView {
                PlayerBarView()
                    .frame(maxWidth: .infinity)

                HStack {
                    PlaylistMultiplicityView(playlists: selection.sorted { $0.id < $1.id })
                }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .layoutPriority(2)
            }
                .preferredColorScheme(.dark)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .layoutPriority(2)
        }
        .listStyle(SidebarListStyle())
    }
}

//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        ContentView(document: .constant(LibraryD))
//    }
//}
