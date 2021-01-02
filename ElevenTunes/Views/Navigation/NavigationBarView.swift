//
//  NavigationBarView.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 02.01.21.
//

import SwiftUI

struct NavigationBarView: View {
    var body: some View {
        HStack {
            Spacer()
                .frame(width: 8)

            Button {
                // TODO Change view
            } label: {
                Image(systemName: "sidebar.left")
            }
            .buttonStyle(BorderlessButtonStyle())
            .disabled(true)
            
            Spacer()
                .frame(width: 20)
            
            Button {
                // TODO Add playlist
            } label: {
                Image(systemName: "music.note.list")
            }
            .buttonStyle(BorderlessButtonStyle())
            .disabled(true)

            Button {
                // TODO Add folder
            } label: {
                Image(systemName: "folder")
            }
            .buttonStyle(BorderlessButtonStyle())
            .disabled(true)
            
            Spacer()
        }
            .frame(maxWidth: .infinity)
            .frame(height: 25)
            .visualEffectBackground(material: .sidebar)
    }
}

struct NavigationBarView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationBarView()
    }
}
