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
            Button {
                // TODO Change view
            } label: {
                Image(systemName: "sidebar.left")
            }
            .buttonStyle(BorderlessButtonStyle())
            .disabled(true)
            .padding(.leading, 8)
            
            Spacer()
                .frame(width: 20)
                    
            Button {
                // TODO Library View
            } label: {
                Image(systemName: "house")
            }
            .buttonStyle(BorderlessButtonStyle())
            .disabled(true)

            Spacer()
                .frame(width: 20)

            Button {
                // TODO Navigator: Back
            } label: {
                Image(systemName: "chevron.backward")
            }
            .buttonStyle(BorderlessButtonStyle())
            .disabled(true)

            Spacer()
                .frame(width: 15)

            Button {
                // TODO Navigator: Forward
            } label: {
                Image(systemName: "chevron.forward")
            }
            .buttonStyle(BorderlessButtonStyle())
            .disabled(true)

            Spacer()
            
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
            .padding(.trailing, 8)
        }
            .frame(maxWidth: .infinity)
            .frame(height: 30)
            .visualEffectBackground(material: .sidebar)
    }
}

struct NavigationBarView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationBarView()
    }
}
