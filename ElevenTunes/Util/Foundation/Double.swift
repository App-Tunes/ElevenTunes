//
//  Double.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 02.01.21.
//

import Foundation

extension Double {
    func format(precision: Int) -> String {
        String(format: "%.\(precision)f", self)
    }
}
