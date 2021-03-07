//
//  HostingView.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 07.03.21.
//

import SwiftUI

@objc(AnyNSHostingView)
class AnyNSHostingView: NSView {
	var hostingView: NSHostingView<AnyView>?
	
	var rootView: AnyView {
		get { hostingView?.rootView ?? AnyView(Rectangle()) }
		set {
			if hostingView == nil {
				hostingView = NSHostingView(rootView: newValue)
				hostingView!.translatesAutoresizingMaskIntoConstraints = false
				setFullSizeContent(hostingView)
			}
			else {
				hostingView!.rootView = newValue
			}
		}
	}
}
