//
//  AudioSetupView.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 20.03.21.
//

import SwiftUI
import Combine

enum AudioDeviceType: Int, Identifiable {
	case av, spotify
	
	var id: Int { rawValue }
}

struct AudioSetupView: View {
	let context: PlayContext
	
    var body: some View {
		ScrollView {
			VStack {
				ForEach([AudioDeviceType.av, AudioDeviceType.spotify]) { type in
					SingleAudioSetupView(context: context, deviceType: type)
					
					if type != .spotify {
						Divider()
					}
				}
			}
		}
			.frame(maxHeight: 500)
    }
}

struct DeviceVolumeView: View {
	@ObservedObject var device: AudioDevice
	
	@State var volume: Double = 1
	
	var body: some View {
		HStack {
			Slider(value: $device.volume, in: 0...1)
			
			PlayerAudioView.volumeImage(device.volume)
				.frame(width: 25, alignment: .leading)
		}
	}
}

struct SingleAudioSetupView: View {
	let context: PlayContext
	let deviceType: AudioDeviceType
	
	@State var device: AudioDevice? = nil
	
	var deviceStream: AnyPublisher<AudioDevice?, Never> {
		switch deviceType {
		case .av:
			return context.$avOutputDevice
				.map { $0 as AudioDevice? }
				.eraseToAnyPublisher()
		case .spotify:
			return context.$spotifyDevice
				.map { $0 as AudioDevice? }
				.eraseToAnyPublisher()
		}
	}
	
	var body: some View {
		VStack {
			HStack {
				switch deviceType {
				case .av:
					Image(systemName: "speaker.wave.2.circle")
						.foregroundColor(.accentColor)
				case .spotify:
					Image(systemName: "speaker.wave.2.circle")
						.foregroundColor(Spotify.color)
				}
				
				if let device = device {
					Text(device.name).bold()
						.padding(.trailing)
						.frame(maxWidth: .infinity, alignment: .leading)
					
					DeviceVolumeView(device: device)
						.frame(width: 150)
				}
				else {
					Text("None Selected").bold()
						.foregroundColor(.secondary)
						.padding(.trailing)
						.frame(maxWidth: .infinity, alignment: .leading)

					Slider(value: .constant(1), in: 0...1)
						.disabled(true)
						.frame(width: 150)

					PlayerAudioView.volumeImage(0)
						.frame(width: 25, alignment: .leading)
				}
			}
				.frame(height: 20)
				.padding()

			if deviceType == .av {
				OutputDeviceSelectorView(proxy: AudioDeviceProxy(context: context))
			}
			else if deviceType == .spotify {
				// TODO
			}
		}
		.onReceive(deviceStream) { device = $0 }
	}
}

//struct AudioSetupView_Previews: PreviewProvider {
//    static var previews: some View {
//        AudioSetupView()
//    }
//}
