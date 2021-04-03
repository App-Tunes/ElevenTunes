//
//  AudioSetupView.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 20.03.21.
//

import SwiftUI
import Combine

struct AudioSetupView: View {
	let context: PlayContext
	
    var body: some View {
		ScrollView {
			VStack {
				AudioProviderView(provider: context.avProvider, current: .init(context, value: \.avOutputDevice))

				if let spotify = context.spotifyProvider {
					Divider()

					AudioProviderView(provider: spotify, current: .init(context, value: \.spotifyDevice))
				}
			}
		}
			.padding(.vertical)
			.frame(maxHeight: 500)
    }
}

struct AudioSetupView_Previews: PreviewProvider {
    static var previews: some View {
		AudioSetupView(context: .init())
    }
}
