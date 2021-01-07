//
//  Badge.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 07.01.21.
//

import SwiftUI

extension View {
    func badge(systemName: String) -> some View {
        ZStack {
            self
            
            GeometryReader { geo in
                Image(systemName: systemName)
                    .resizable().aspectRatio(contentMode: .fit)
                    .frame(width: geo.size.width / 2, height: geo.size.height / 2)
                    .position(x: geo.size.width / 4 * 3, y: geo.size.height / 4 * 3)
            }
        }
    }
}
