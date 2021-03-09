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
    @State var mainPlaylist: Playlist

	@ObservedObject var navigator: Navigator = .init()

    var body: some View {
        HSplitView {
            ZStack(alignment: .top) {
				NavigatorView(directory: mainPlaylist, navigator: navigator)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .listStyle(SidebarListStyle())

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

				PlaylistMultiplicityView(playlists: navigator.playlists)
                    .frame(minWidth: 200, idealWidth: 250, maxWidth: .infinity, minHeight: 100, idealHeight: 400, maxHeight: .infinity)
                    .layoutPriority(2)
            }
                .preferredColorScheme(.dark)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .layoutPriority(2)
        }
    }
}

//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        ContentView(document: .constant(LibraryD))
//    }
//}
