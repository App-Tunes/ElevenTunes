//
//  Set.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 28.12.20.
//

import Foundation

extension Set {
    func alIfContains(_ element: Element) -> Set<Element> {
        contains(element) ? self : [element]
    }
}
