//
//  OutputDeviceSelector.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 20.03.21.
//

import SwiftUI
import AVFoundation

@available(OSX 10.15, *)
class AudioDeviceProxy: NSObject, ObservableObject {
	enum Option: Equatable {
		case systemDefault
				
		var id: UInt32 {
			switch self {
			case .systemDefault:
				return 0
			}
		}
		
		var name: String {
			switch self {
			case .systemDefault:
				return "System Default"
			}
		}
		
		var icon: String {
			switch self {
			case .systemDefault:
				return "􀀀"
			}
		}
	}
	
	override init() {
		super.init()
		
//		AKManager.addObserver(self, forKeyPath: #keyPath(AKManager.outputDevices), options: [.new], context: nil)
//		AKManager.addObserver(self, forKeyPath: #keyPath(AKManager.outputDevice), options: [.new], context: nil)
	}
	
	override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
		print("Change!")
		objectWillChange.send()
	}
	
	func link(_ option: Option) throws {
		guard current != option else {
			return // No need
		}
		
		
	}
	
	var options: [Option] {
		return [.systemDefault]
	}
	
	var current: Option? {
		.systemDefault
	}
	
	var currentVolume: Double = 1
//	{
//		get {
//			var volume = 0.0
//			_ = AudioUnitGetParameter(AudioUnitGetSys, kMatrixMixerParam_Volume, kAudioUnitScope_Global, 0, &volume);
//			return volume
//		}
//
//		set {
//
//		}
//	}
}

@available(OSX 10.15, *)
struct OutputDeviceSelectorView: View {
	@ObservedObject var proxy = AudioDeviceProxy()
	@State private var pressOption: AudioDeviceProxy.Option?
	@State private var hoverOption: AudioDeviceProxy.Option?

	func optionView(_ option: AudioDeviceProxy.Option) -> some View {
		HStack {
			Text(option.icon)
				.frame(width: 25, alignment: .leading)
			Text(option.name)
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
			HStack {
				Text("Output Device").bold()
					.padding(.trailing)
				
				Slider(value: $proxy.currentVolume, in: 0...1)
				
				Text(
					proxy.currentVolume == 0 ? "􀊡" :
					proxy.currentVolume < 0.33 ? "􀊥" :
					proxy.currentVolume < 0.66 ? "􀊧" :
					"􀊩"
				)
				.frame(width: 25, alignment: .leading)
			}
				.padding()
			
			ForEach(proxy.options, id: \.id) { option in
				optionView(option)
					.padding(.horizontal)
					.padding(.vertical, 10)
					.background(backgroundOpacity(option).map(Color.gray.opacity))
					.onHover { over in
						self.hoverOption = over ? option : nil
					}
					.onTapGesture {
						do {
							try self.proxy.link(option)
						}
						catch let error {
							NSAlert.informational(title: "Unable to switch output device", text: error.localizedDescription)
						}
					}
					.onLongPressGesture(pressing: { isDown in
						self.pressOption = isDown ? option : nil
					}) {}
			}
		}
	}
}

@available(OSX 10.15, *)
struct OutputDeviceSelectorView_Previews: PreviewProvider {
	static var previews: some View {
		OutputDeviceSelectorView()
	}
}
