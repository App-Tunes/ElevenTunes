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
				AudioProviderView(provider: AVAudioDeviceProvider(context: context))
				
//				Divider()
//				
//				AudioProviderView(provider: SpotifyAudioDeviceProvider(context: context))
			}
		}
			.frame(maxHeight: 500)
    }
}

//struct AudioSetupView_Previews: PreviewProvider {
//    static var previews: some View {
//        AudioSetupView()
//    }
//}
