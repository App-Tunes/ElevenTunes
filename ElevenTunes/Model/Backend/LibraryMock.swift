//
//  Transient.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 18.12.20.
//

import Foundation
import AVFoundation
import Combine
import Cocoa

class LibraryMock {
    static func children(title: String = "Mock Directory") -> [TransientPlaylist] {
        [
			playlist(title: "\(title) -> 1"),
            playlist(title: "\(title) -> 2")
        ]
    }
    
    static func directory(title: String = "Mock Directory") -> TransientPlaylist {
		let children = self.children(title: title)
        return TransientPlaylist(.playlists, attributes: .unsafe([
            .title: title,
			.children: children
        ]))
    }
    
    static func playlist(title: String = "Mock Playlist") -> TransientPlaylist {
        let tracks = [
            "\(title) -> 1", "\(title) -> 2", "\(title) -> 3",
		].map { track(title: $0) }
        
        return TransientPlaylist(.tracks, attributes: .unsafe([
            .title: title,
			.tracks: tracks
        ]))
    }

    static func track(title: String = "Mock Track") -> MockTrack {
        MockTrack(attributes: .unsafe([
            .title: title,
			.genre: "Mock House",
			.year: 2021,
			.key: MusicalKey(note: .D, mode: .major),
			.tempo: Tempo(bpm: 123),
			.artists: [TransientArtist(attributes: .unsafe([.title: "Some Artist"])), TransientArtist(attributes: .unsafe([.title: "Some Other Artist"]))],
			.album: TransientAlbum(attributes: .unsafe([.title: "Best Album"])),
			.waveform: waveform()
        ]))
    }
	
	static func waveform() -> Waveform {
		Waveform(
			loudness: (0...80).map {
				(sin(Float($0) / 3) + 1) / 2
			},
			pitch: (0...80).map {
				(sin(Float($0) / 2) + 1) / 2
			}
		)
	}
}
