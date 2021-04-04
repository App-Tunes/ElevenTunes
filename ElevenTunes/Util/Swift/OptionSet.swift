//
//  OptionSet.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 29.12.20.
//

extension FixedWidthInteger {
    init(bitComponents : [Self]) {
        self = bitComponents.reduce(0, +)
    }

    var bitComponents : [Self] {
        (0 ..< Self.bitWidth).map { 1 << $0 } .filter { self & $0 != 0 }
    }
}

extension OptionSet where RawValue: FixedWidthInteger, Self == Self.Element {
    var components : [Self] { rawValue.bitComponents.map(Self.init) }
}
