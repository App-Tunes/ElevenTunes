//
//  GeoChange.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 09.04.21.
//

import SwiftUI

extension View {
	func onGeoChange(_ fun: @escaping (GeometryProxy) -> Void) -> some View {
		let viewFun: (GeometryProxy) -> Self = { geo in
			fun(geo)
			return self
		}
		
		return GeometryReader(content: viewFun)
	}
}
