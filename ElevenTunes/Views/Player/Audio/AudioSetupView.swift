//
//  AudioSetupView.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 20.03.21.
//

import SwiftUI

struct AudioSetupView: View {
	let context: PlayContext
	
    var body: some View {
		OutputDeviceSelectorView(proxy: AudioDeviceProxy(context: context))
    }
}

//struct AudioSetupView_Previews: PreviewProvider {
//    static var previews: some View {
//        AudioSetupView()
//    }
//}
