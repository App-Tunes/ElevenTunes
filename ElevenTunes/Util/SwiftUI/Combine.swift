//
//  Combine.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 01.01.21.
//

import SwiftUI
import Combine

extension View {
    func onReceive<T>(_ publisher: AnyPublisher<T, Never>?, default def: T, perform: @escaping (T) -> Void) -> some View {
        onReceive(publisher ?? Just(def).eraseToAnyPublisher(), perform: perform)
    }
}
