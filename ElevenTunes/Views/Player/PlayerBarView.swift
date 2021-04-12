//
//  PlayerBarView.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 15.12.20.
//

import SwiftUI

struct PlayerBarView: View {
	@Environment(\.player) private var player: Player!

    var body: some View {
		CurrentPlayPositionView(snapshot: .init(track: player.$current))
			.background(
				LinearGradient(gradient: Gradient(colors: [Color.black.opacity(0.6), .clear]).applying(iterations: 20) { pow($0, 0.4) }, startPoint: .bottom, endPoint: .top)
					.background(
						PlayerMilkyCoverView()
							.visualEffectOnTop(material: .underWindowBackground, blendingMode: .withinWindow, emphasized: true)
					)
					.edgesIgnoringSafeArea(.top)
			)
    }
}

struct PlayerBarView_Previews: PreviewProvider {
    static var previews: some View {
        PlayerBarView()
			.environment(\.player, Player(context: .init()))
    }
}
