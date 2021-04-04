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
        VStack {
            ToolbarView(player: player)
            // The height doesn't count towards the frame edges, so this means "minimum possible while filling the title bar
                .edgesIgnoringSafeArea([.top, .leading])
                .frame(height: 0)

			CurrentPlayPositionView(player: player)
				.frame(minHeight: 20, idealHeight: 30, maxHeight: 50)
                .layoutPriority(2)
        }
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
