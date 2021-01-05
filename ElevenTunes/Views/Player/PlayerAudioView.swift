//
//  PlayerAudioView.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 01.01.21.
//

import SwiftUI

struct PlayerAudioView: View {
    @State var player: Player
    
    @State var volume: Double = 1

    var body: some View {
        HStack {
            Slider(value: $volume, in: 0...1)
                .frame(width: 80)
                .disabled(true)
            
            Image(systemName: "speaker.wave.3.fill")
                .font(.system(size: 10))
                .foregroundColor(.secondary)
            
            Button(action: {
                
            }) {
                Image(systemName: "airplayaudio")
                    .font(.system(size: 18))
            }
                .buttonStyle(BorderlessButtonStyle())
                .disabled(true)
                .padding(.leading, 3)
        }
    }
}
