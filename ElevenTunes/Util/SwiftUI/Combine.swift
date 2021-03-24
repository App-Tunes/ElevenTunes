//
//  Combine.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 01.01.21.
//

import SwiftUI
import Combine

extension View {
	func onReceive<P, T>(_ publisher: P?, default def: T, perform: @escaping (T) -> Void) -> some View where P: Publisher, P.Output == T, P.Failure == Never {
		onReceive(publisher?.eraseToAnyPublisher() ?? Just(def).eraseToAnyPublisher(), perform: perform)
    }
}
