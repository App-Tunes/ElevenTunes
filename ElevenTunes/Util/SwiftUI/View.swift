//
//  View.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 08.04.21.
//

import SwiftUI

extension View {
	@ViewBuilder func hidden(_ hide: Bool) -> some View {
		if hide { self.hidden() }
		else { self }
	}
}
