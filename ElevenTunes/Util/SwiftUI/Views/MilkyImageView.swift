//
//  MilkyImageView.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 01.01.21.
//

import SwiftUI

struct MilkyImageView: View {
    let image: NSImage?
    
    var body: some View {
        Image(nsImage: image ?? NSImage())
            .resizable()
            .visualEffectOnTop(material: .underWindowBackground, blendingMode: .withinWindow, emphasized: true)
    }
}

//struct MilkyImageView_Previews: PreviewProvider {
//    static var previews: some View {
//        MilkyImageView()
//    }
//}
