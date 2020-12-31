//
//  Link.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 31.12.20.
//

import Foundation
import SwiftUI
import AppKit

struct UnderlinedLink: View {
    @State var description: String
    @State var destination: URL

    @State var isHovering = false
    
    var body: some View {
        // For some reason link has HUGE padding
//        Link(destination: destination) {
        //            Text(description)
        //                .underline(isHovering)
        //        }
            Text(description)
                .underline(isHovering)
                .onTapGesture {
                    NSWorkspace.shared.open(destination)
                }
                .padding(0)
                .onHover { isHovering = $0 }
    }
}
