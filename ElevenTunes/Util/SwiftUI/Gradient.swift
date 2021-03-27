//
//  Gradient.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 01.01.21.
//

import SwiftUI

extension Gradient {
    func smoothstep(iterations: Int) -> Gradient {
        applying(iterations: iterations) { (x: CGFloat) -> CGFloat in
			x * x * (3.0 - 2.0 * x)
		}
    }
    
    func smootherstep(iterations: Int) -> Gradient {
        applying(iterations: iterations) { (x: CGFloat) -> CGFloat in
			let result: CGFloat = pow(x, 3) * (6 * pow(x, 2) - 15 * x + 10)
			return result
        }
    }
    
    func applying(iterations: Int, _ fun: (CGFloat) -> CGFloat) -> Gradient {
        Gradient(colors: (0 ..< iterations).map { i in
            sample(at: fun(CGFloat(i) / CGFloat(iterations - 1)))
        })
    }
    
    func sample(at location: CGFloat) -> Color {
        guard let index = stops.firstIndex(where: { location < $0.location }) else {
            return stops.last!.color
        }
        if index <= 0 {
            return stops.first!.color
        }
        
        return Color.lerpHSVA(
            by: location - CGFloat(index - 1),
            stops[index - 1].color,
            stops[index].color
        )
    }
}

extension Color {
    static func lerpHSVA(by lerp: CGFloat, _ lhs: Color, _ rhs: Color) -> Color {
        let left = lhs.hsva
        let right = rhs.hsva
        
        return Color(
            hue: Double(CGFloat.lerp(by: lerp, left.hue, right.hue)),
            saturation: Double(CGFloat.lerp(by: lerp, left.saturation, right.saturation)),
            brightness: Double(CGFloat.lerp(by: lerp, left.value, right.value)),
            opacity: Double(CGFloat.lerp(by: lerp, left.alpha, right.alpha))
        )
    }
}

extension FloatingPoint {
    static func lerp(by lerp: Self, _ lhs: Self, _ rhs: Self) -> Self {
        return lhs + (lerp * (rhs - lhs))
    }
}
