//
//  AudioSetupView.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 20.03.21.
//

import SwiftUI

struct AudioSetupView: View {
    var body: some View {
        OutputDeviceSelectorView()
    }
}

struct AudioSetupView_Previews: PreviewProvider {
    static var previews: some View {
        AudioSetupView()
    }
}
