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
	let navigator: Navigator
	
    var body: some View {
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

//struct MainContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        MainContentView()
//    }
//}
