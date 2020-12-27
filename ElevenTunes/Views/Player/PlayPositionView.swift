//
//  WaveformView.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 15.12.20.
//

import SwiftUI
import AVFoundation

struct VBar : Shape {
    var position: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()

        path.move(to: .init(x: rect.size.width * position, y: rect.size.height))
        path.addLine(to: .init(x: rect.size.width * position, y: 0))

        return path
    }

    var animatableData: CGFloat {
        get { return position }
        set { position = newValue }
    }
}

struct PlayPositionView: View {
    @State var player: SinglePlayer
    @State var playing: AnyAudioEmitter?
    @State var playerState: PlayerState = .init(isPlaying: false, currentTime: nil)
    @State var position: CGFloat? = nil

    var timeLeft: String {
        guard let time = playing?.duration else {
            return ""
        }
        
        let totalSeconds = Int(time)
        let hours: Int = Int(totalSeconds / 3600)
        
        let minutes: Int = Int(totalSeconds % 3600 / 60)
        let seconds: Int = Int((totalSeconds % 3600) % 60)

        if hours > 0 {
            return String(format: "%i:%02i:%02i", hours, minutes, seconds)
        } else {
            return String(format: "%i:%02i", minutes, seconds)
        }
    }
    
    func updatePosition() {
        guard let playing = playing else {
            position = nil
            return
        }
        
        guard let duration = playing.duration, let currentTime = playerState.currentTime else {
            position = nil // TODO Show infinite loading-bar style progress bar
            return
        }
        
        withAnimation(.instant) {
            position = CGFloat(currentTime / duration)
        }

        if playerState.isPlaying {
            let timeLeft = duration - currentTime
            
            withAnimation(.linear(duration: timeLeft)) {
                position = 1
            }
        }
    }
    
    func move(to point: CGFloat) {
        guard let playing = playing else {
            return
        }
        
        do {
            try playing.move(to: playing.duration.map { $0 * TimeInterval(point) } ?? 0 )
        } catch let error {
            appLogger.error("Error moving to time: \(error)")
        }
    }
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                if let position = position {
                    VBar(position: position)
                        .stroke(lineWidth: max(1, min(2, 3 - geo.size.height / 20)))
                }
                
                HStack {
                    Text(playing != nil ? "0:00" : "")
                        .padding(.leading)
                    
                    Spacer()

                    Text(timeLeft)
                        .padding(.trailing)
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .local)
                    .onEnded { value in
                        move(to: value.location.x / geo.size.width)
                    }
            )
        }
        .onReceive(player.$playing) { playing in
            self.playing = playing
        }
        .onReceive(player.$state) { state in
            self.playerState = state
            updatePosition()
        }
        .frame(minHeight: 20, maxHeight: 50)
    }
}

struct PlayPositionView_Previews: PreviewProvider {
    static var previews: some View {
        PlayPositionView(player: SinglePlayer())
    }
}
