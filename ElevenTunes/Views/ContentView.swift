//
//  ContentView.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 15.12.20.
//

import SwiftUI

struct PlayerEnvironmentKey: EnvironmentKey {
    static let defaultValue: Player = Player()
}
struct TrackInterpreterEnvironmentKey: EnvironmentKey {
    static let defaultValue: TrackInterpreter = TrackInterpreter(spotify: SpotifyEnvironmentKey.defaultValue)
}
struct PlaylistInterpreterEnvironmentKey: EnvironmentKey {
    static let defaultValue: PlaylistInterpreter = PlaylistInterpreter(spotify: SpotifyEnvironmentKey.defaultValue)
}

extension EnvironmentValues {
    var player: Player {
        get { self[PlayerEnvironmentKey] }
        set { self[PlayerEnvironmentKey] = newValue }
    }

    var trackInterpreter: TrackInterpreter {
        get { self[TrackInterpreterEnvironmentKey] }
        set { self[TrackInterpreterEnvironmentKey] = newValue }
    }

    var playlistInterpreter: PlaylistInterpreter {
        get { self[PlaylistInterpreterEnvironmentKey] }
        set { self[PlaylistInterpreterEnvironmentKey] = newValue }
    }
}

struct ContentView: View {
    @Binding var document: ElevenTunesDocument

    @Environment(\.spotify) private var spotify: Spotify

    let player = Player()
    
    var trackInterpreter: TrackInterpreter { _trackInterpreter! }
    var _trackInterpreter: TrackInterpreter? = nil

    var playlistInterpreter: PlaylistInterpreter { _playlistInterpreter! }
    var _playlistInterpreter: PlaylistInterpreter? = nil

    let directory = LibraryMock.directory()
    
    init(document: Binding<ElevenTunesDocument>) {
        self._document = document
        _trackInterpreter = TrackInterpreter(spotify: spotify)
        _playlistInterpreter = PlaylistInterpreter(spotify: spotify)
    }
    
    var body: some View {
        VSplitView {
            PlayerBarView()
                .frame(maxWidth: .infinity)

            NavigatorView(directory: directory)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .layoutPriority(2)
        }
            .environment(\.player, player)
            .environment(\.trackInterpreter, trackInterpreter)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(document: .constant(ElevenTunesDocument()))
    }
}
