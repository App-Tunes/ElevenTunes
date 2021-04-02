//
//  OutputDeviceSelector.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 20.03.21.
//

import SwiftUI
import AVFoundation

@available(OSX 10.15, *)
protocol AudioDeviceProvider: ObservableObject {
	associatedtype Option: AudioDevice
	
	var options: [Option] { get }

	var icon: Image { get }
	var color: Color { get }
}

struct ExtendedAudioDeviceView<Device: AudioDevice>: View {
	@ObservedObject var device: Device
		
	var body: some View {
		HStack {
			Slider(value: $device.volume, in: 0...1)
			
			PlayerAudioView.volumeImage(device.volume)
				.frame(width: 25, alignment: .leading)
		}
	}
}


struct AudioProviderView<Provider: AudioDeviceProvider>: View {
	@ObservedObject var provider: Provider
	@ObservedObject var current: ObservableBinding<Provider.Option?>
	
	@State private var pressOption: Provider.Option?
	@State private var hoverOption: Provider.Option?

	func optionView(_ option: Provider.Option) -> some View {
		HStack {
			Text(option.icon)
				.frame(width: 25, alignment: .center)
			Text(option.name ?? "Unknown Device")
				.frame(width: 300, alignment: .leading)
			
			Text("􀆅").foregroundColor(Color.white.opacity(
				current.value == option ? 1 :
				hoverOption == option ? 0.2 :
				0
			))
				.frame(width: 25, alignment: .leading)
		}
	}
	
	func backgroundOpacity(_ option: Provider.Option) -> Double? {
		pressOption == option ? 0.4 :
		hoverOption == option ? 0.2 :
			nil
	}

	var body: some View {
		VStack {
			HStack {
				provider.icon
					.resizable()
					.foregroundColor(provider.color)
					.frame(width: 14, height: 14)

				if let device = current.value {
					Text(device.name ?? "Unknown Device").bold()
						.padding(.trailing)
						.frame(maxWidth: .infinity, alignment: .leading)
					
					ExtendedAudioDeviceView(device: device)
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
				.padding(.horizontal)
				.padding(.vertical, 4)

			VStack(alignment: .leading, spacing: 0) {
				ForEach(provider.options, id: \.id) { option in
					optionView(option)
						.padding(.horizontal)
						.padding(.vertical, 8)
						.background(backgroundOpacity(option).map(Color.gray.opacity))
						.onHover { over in
							self.hoverOption = over ? option : nil
						}
						.onTapGesture {
							if self.current.value == option {
								self.current.value = nil
							}
							else {
								self.current.value = option
							}
						}
						.onLongPressGesture(pressing: { isDown in
							self.pressOption = isDown ? option : nil
						}) {}
				}
			}
		}
	}
}

//@available(OSX 10.15, *)
//struct OutputDeviceSelectorView_Previews: PreviewProvider {
//	static var previews: some View {
//		OutputDeviceSelectorView()
//	}
//}
