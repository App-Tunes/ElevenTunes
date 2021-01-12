//
//  WhileActive.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 11.01.21.
//

import SwiftUI
import Combine

struct WhileActive<Content: View>: View {
	let content: Content
	let cancellable: AnyCancellable?
	
    var body: some View {
        content
    }
}

extension View {
	func whileActive(_ cancellable: @autoclosure () -> AnyCancellable?) -> WhileActive<Self> {
		WhileActive(content: self, cancellable: cancellable())
	}
}
