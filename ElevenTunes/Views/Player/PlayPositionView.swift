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
    let player: SinglePlayer

	let playing: AudioTrack
	/// Single move step in seconds
	let moveStep: CGFloat?

    @State var playerState: PlayerState = .init(isPlaying: false, currentTime: nil)

    @State var position: CGFloat? = nil

	// 'free' moues position vs 'stepped' are handled differently,
	// so 'stepped' is animated properly and the jump can be exact
	@State var mousePosition: CGFloat? = nil
	@State var mousePositionSteps: Int? = nil
    @State var isDragging = false
    
    func updatePosition() {
        guard let duration = playing.duration, let currentTime = playing.currentTime else {
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
		guard let duration = playing.duration else {
			return
		}
		
		let pointTime = TimeInterval(point) * duration

        do {
			if
				!NSEvent.modifierFlags.contains(.option),
				let moveStep = moveStep.map({ TimeInterval($0) }),
				let currentTime = playing.currentTime
			{
				let steps = round((pointTime - currentTime) / moveStep)
				if abs(steps) < 0.0001 {
					return // Why bother? 0 Steps
				}
				
				try playing.move(to: max(0, min(duration, currentTime + steps * moveStep)))
			}
			else {
				try playing.move(to: max(0, min(duration, pointTime)))
			}
        } catch let error {
            appLogger.error("Error moving to time: \(error)")
        }
    }
	
	func updateMousePosition(_ position: CGFloat) {
		let position = max(0, min(1, position))
		
		guard
			let duration = playing.duration.map({ CGFloat($0) }),
			let moveStep = moveStep.map({ CGFloat($0) }),
			let currentTime = playing.currentTime.map({ CGFloat($0) }),
			!NSEvent.modifierFlags.contains(.option)
		else {
			mousePosition = position
			mousePositionSteps = nil
			return
		}
		
		mousePositionSteps = Int(round((position * duration - currentTime) / moveStep))
		mousePosition = nil
		updatePosition()  // To start animating mouse too
	}
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                let width = max(1, min(2, 3 - geo.size.height / 20))
                
                if let position = position {
                    VBar(position: position)
                        .stroke(lineWidth: width)
						.id("playerbar")
					
					if let mousePositionSteps = mousePositionSteps, let duration = playing.duration, let moveStep = moveStep {
						VBar(position: position + CGFloat(mousePositionSteps) * moveStep / CGFloat(duration))
							.stroke(lineWidth: width)
							.opacity(isDragging ? 1 : 0.5)
							.id("mousebar")
					}
                }
                
                if playing.duration != nil, let mousePosition = mousePosition {
                    VBar(position: mousePosition)
                        .stroke(lineWidth: width)
                        .opacity(isDragging ? 1 : 0.5)
						.id("mousebar")
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .local)
                    .onChanged { value in
                        updateMousePosition(value.location.x / geo.size.width)
                        isDragging = true
                    }
                    .onEnded { value in
						move(to: value.location.x / geo.size.width)
                        isDragging = false
						mousePosition = nil
						mousePositionSteps = nil
                    }
            )
            .onHoverLocation { location in
                updateMousePosition(location.x / geo.size.width)
            } onEnded: {
                mousePosition = nil
				mousePositionSteps = nil
            }
        }
        .onReceive(player.$state) { state in
            self.playerState = state
            updatePosition()
        }
    }
}

struct PlayPositionLabelsView: View {
	let playingAudio: AudioTrack
	
	var timeLeft: String {
		guard let time = playingAudio.duration else {
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
		HStack {
			Text("0:00")
				.foregroundColor(.secondary)
				.padding(.leading)
			
			Spacer()

			Text(timeLeft)
				.foregroundColor(.secondary)
				.padding(.trailing)
		}
	}
}

struct PlayPositionView: View {
    let player: Player
	
	@State var playingAudio: AudioTrack?
	@State var playingTrack: AnyTrack?
	@State var tempo: Tempo?

	var moveStep: CGFloat? {
		return tempo.map { CGFloat(1 / $0.bps) * 32 }
	}
	
    var body: some View {
        GeometryReader { geo in
            ZStack {
                if let playingAudio = playingAudio {
					PlayPositionBarsView(
						player: player.singlePlayer,
						playing: playingAudio,
						moveStep: moveStep
					)
					
					if geo.size.height >= 20 {
						PlayPositionLabelsView(playingAudio: playingAudio)
					}
                }
            }
        }
		.onReceive(player.singlePlayer.$playing) {
			self.playingAudio = $0
		}
		.onReceive(player.$current) {
			self.playingTrack = $0
		}
		.whileActive(playingTrack?.demand([.bpm]))
		.onReceive(playingTrack?.attribute(TrackAttribute.bpm).map(\.value), default: nil) {
			self.tempo = $0
		}
        // TODO hugging / compression resistance:
        // setting min height always compressed down to min height :<
        .frame(minHeight: 20, idealHeight: 30, maxHeight: 50)
    }
}

//struct PlayPositionView_Previews: PreviewProvider {
//    static var previews: some View {
//        PlayPositionView(player: SinglePlayer())
//    }
//}
