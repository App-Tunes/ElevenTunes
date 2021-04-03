//
//  NSWorkspace.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 03.04.21.
//

import Foundation

extension NSWorkspace {
	func visit(_ url: URL) {
		if url.isFileURL {
			activateFileViewerSelecting([url])
//			selectFile(nil, inFileViewerRootedAtPath: url.path)
		}
		else {
			NSWorkspace.shared.open(url)
		}
	}
}
