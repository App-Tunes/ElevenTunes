//
//  ResampleToSize.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 02.04.21.
//

import Foundation

extension ResampleToSize {
	static func resampleLinear(data: [Float], toSize count: Int) -> [Float] {
		data.withUnsafeBufferPointer { src in
			var array = [Float](repeating: 0, count: count)
			array.withUnsafeMutableBufferPointer { dst in
				resampleLinear(src.baseAddress!, count: Int32(src.count), dst: dst.baseAddress!, count: Int32(dst.count))
				return
			}
			return array
		}
	}
}
