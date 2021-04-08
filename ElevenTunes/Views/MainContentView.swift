//
//  MainContentView.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 05.04.21.
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

struct MainContentView: View {
	@ObservedObject var navigator: Navigator
	
    var body: some View {
		VSplitView {
			PlayerBarView()
				.frame(maxWidth: .infinity, minHeight: 20, idealHeight: 30, maxHeight: 50)

			PlaylistMultiplicityView(playlists: navigator.playlists)
				.frame(maxWidth: .infinity, minHeight: 200, idealHeight: 400, maxHeight: .infinity)
				.layoutPriority(2)
		}
			.frame(minWidth: 700, idealWidth: 800, maxWidth: .infinity, minHeight: 350, idealHeight: 400, maxHeight: .infinity)
			.layoutPriority(2)
    }
}

//struct MainContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        MainContentView()
//    }
//}
