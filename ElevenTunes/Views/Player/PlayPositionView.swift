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

struct PlayPositionBarsView: View {
    @State var player: SinglePlayer

    let playing: AnyAudioEmitter
    @State var playerState: PlayerState = .init(isPlaying: false, currentTime: nil)

    @State var position: CGFloat? = nil
    @State var mousePosition: CGFloat? = nil
    @State var isDragging = false
    
    func updatePosition() {
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
        do {
            try playing.move(to: playing.duration.map { $0 * TimeInterval(point) } ?? 0 )
        } catch let error {
            appLogger.error("Error moving to time: \(error)")
        }
    }
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                let width = max(1, min(2, 3 - geo.size.height / 20))
                
                if let position = position {
                    VBar(position: position)
                        .stroke(lineWidth: width)
                }
                
                if playing.duration != nil, let mousePosition = mousePosition {
                    VBar(position: mousePosition)
                        .stroke(lineWidth: width)
                        .opacity(isDragging ? 1 : 0.5)
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .local)
                    .onChanged { value in
                        mousePosition = value.location.x / geo.size.width
                        isDragging = true
                    }
                    .onEnded { value in
                        move(to: value.location.x / geo.size.width)
                        isDragging = false
                    }
            )
            .onHoverLocation { location in
                self.mousePosition = location.x / geo.size.width
            } onEnded: {
                self.mousePosition = nil
            }
        }
        .onReceive(player.$state) { state in
            self.playerState = state
            updatePosition()
        }
    }
}

struct PlayPositionView: View {
    @State var player: SinglePlayer
    @State var playing: AnyAudioEmitter?

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
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                if let playing = playing {
                    PlayPositionBarsView(player: player, playing: playing)
                }
                
                if geo.size.height >= 20 {
                    HStack {
                        Text(playing != nil ? "0:00" : "")
                            .foregroundColor(.secondary)
                            .padding(.leading)
                        
                        Spacer()

                        Text(timeLeft)
                            .foregroundColor(.secondary)
                            .padding(.trailing)
                    }
                }
            }
        }
        .onReceive(player.$playing) { playing in
            self.playing = playing
        }
        // TODO hugging / compression resistance:
        // setting min height always compressed down to min height :<
        .frame(minHeight: 20, idealHeight: 30, maxHeight: 50)
    }
}

struct PlayPositionView_Previews: PreviewProvider {
    static var previews: some View {
        PlayPositionView(player: SinglePlayer())
    }
}
