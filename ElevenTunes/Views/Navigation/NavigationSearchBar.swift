//
//  NavigationSearchBar.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 01.01.21.
//

import SwiftUI

struct NavigationSearchBar: View {
    @State var text: String = ""
    
    var body: some View {
        TextField("􀊫 Search...", text: $text)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .disabled(true)
    }
}
