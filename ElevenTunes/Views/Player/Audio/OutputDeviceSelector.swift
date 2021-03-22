//
//  OutputDeviceSelector.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 20.03.21.
//

import SwiftUI
import AVFoundation

@available(OSX 10.15, *)
class AudioDeviceProxy: ObservableObject {
	typealias Option = AVAudioDevice
	
	let context: PlayContext

	init(context: PlayContext) {
		self.context = context
		
//		AKManager.addObserver(self, forKeyPath: #keyPath(AKManager.outputDevices), options: [.new], context: nil)
//		AKManager.addObserver(self, forKeyPath: #keyPath(AKManager.outputDevice), options: [.new], context: nil)
	}
	
//	override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
//		print("Change!")
//		objectWillChange.send()
//	}
	
	func toggle(_ option: Option) {
		if current == option {
			context.avOutputDevice = nil
		}
		else {
			context.avOutputDevice = option
		}
	}
	
	var options: [Option] {
		[.systemDefault] + AudioDeviceFinder.findDevices()
	}
	
	var current: Option? { context.avOutputDevice }
	
	var currentVolume: Double {
		get { current?.volume ?? 1}
		set { current?.volume = newValue }
	}
}

@available(OSX 10.15, *)
struct OutputDeviceSelectorView: View {
	@ObservedObject var proxy: AudioDeviceProxy
	
	@State private var pressOption: AudioDeviceProxy.Option?
	@State private var hoverOption: AudioDeviceProxy.Option?

	func optionView(_ option: AudioDeviceProxy.Option) -> some View {
		HStack {
			Text(option.icon)
				.frame(width: 25, alignment: .leading)
			Text(option.name ?? "Unknown Device")
				.frame(width: 300, alignment: .leading)
			
			Text("􀆅").foregroundColor(Color.white.opacity(
				proxy.current == option ? 1 :
				hoverOption == option ? 0.2 :
				0
			))
				.frame(width: 25, alignment: .leading)
		}
	}
	
	func backgroundOpacity(_ option: AudioDeviceProxy.Option) -> Double? {
		pressOption == option ? 0.4 :
		hoverOption == option ? 0.2 :
			nil
	}

	var body: some View {
		VStack(alignment: .leading, spacing: 0) {			
			ForEach(proxy.options, id: \.deviceID) { option in
				optionView(option)
					.padding(.horizontal)
					.padding(.vertical, 10)
					.background(backgroundOpacity(option).map(Color.gray.opacity))
					.onHover { over in
						self.hoverOption = over ? option : nil
					}
					.onTapGesture {
						self.proxy.toggle(option)
					}
					.onLongPressGesture(pressing: { isDown in
						self.pressOption = isDown ? option : nil
					}) {}
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
