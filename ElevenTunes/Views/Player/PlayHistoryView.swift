//
//  PlayHistoryView.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 03.01.21.
//

import SwiftUI

struct PlayHistoryAccessorView: View {
    var body: some View {
        Button(action: {
            
        }) {
            Image(systemName: "list.bullet")
                .font(.system(size: 18))
        }
            .buttonStyle(BorderlessButtonStyle())
            .disabled(true)
    }
}

//struct PlayHistoryView: View {
//    var body: some View {
//        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
//    }
//}
//
//struct PlayHistoryView_Previews: PreviewProvider {
//    static var previews: some View {
//        PlayHistoryView()
//    }
//}
