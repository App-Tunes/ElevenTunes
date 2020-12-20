//
//  FilterBarView.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 15.12.20.
//

import SwiftUI

struct FilterBarView: View {
    var body: some View {
        HStack {
            Text("Filter Bar!")
        }
            .frame(minWidth: 200)
            .frame(height: 50)
    }
}

struct FilterBarView_Previews: PreviewProvider {
    static var previews: some View {
        FilterBarView()
    }
}
