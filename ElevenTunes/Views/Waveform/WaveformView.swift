//
//  WaveformView.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 01.04.21.
//

import SwiftUI
import Combine

struct WaveformView: View {
	let data: [CGFloat]
	let color: [Color]

	var body: some View {
		let count = min(data.count, color.count)
		
		GeometryReader { geo in
			HStack(alignment: .bottom, spacing: 2) {
				ForEach(0..<count) { i in
					Rectangle()
						.foregroundColor(color[i])
						.frame(height: geo.size.height * max(0, min(1, data[i])), alignment: .bottom)
				}
				.frame(height: geo.size.height, alignment: .bottom)
			}
		}
			.drawingGroup()
			.id(count)
	}
}

struct ResamplingWaveformView: View {
	var gradient: [Color]
	@ObservedObject var waveform: ResamplingWaveform

	var body: some View {
		WaveformView(
			data: waveform.loudness.map { CGFloat($0) },
			color: waveform.pitch.map {
				$0.isFinite ? gradient[Int(round(max(0, min(1, $0)) * 255))] : .white
			}
		)
			.onGeoChange { geo in
				waveform.updateSamples(Int(geo.size.width / 4))
			}
	}
}

struct ResamplingWaveformView_Previews: PreviewProvider {
    static var previews: some View {
		ResamplingWaveformView(
			gradient: Gradients.pitch, waveform: ResamplingWaveform.constant(LibraryMock.waveform())
		)
			.frame(width: 500, height: 100)
    }
}
