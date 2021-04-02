//
//  WaveformView.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 01.04.21.
//

import SwiftUI

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
						.frame(height: geo.size.height * max(0, min(1, data[i])))
				}
			}
		}
			.drawingGroup()
			.id(count)
	}
}

struct ResamplingWaveformView: View {
	var gradient: [Color]
	var waveform: Waveform

	var body: some View {
		GeometryReader { geo in
			let samples = Int(geo.size.width / 5)
			
			if samples < waveform.count {
				WaveformView(
					data: ResampleToSize.resampleLinear(data: waveform.loudness, toSize: samples).map {
						CGFloat($0)
					},
					color: ResampleToSize.resampleLinear(data: waveform.pitch, toSize: samples).map {
						gradient[max(0, min(gradient.count, Int($0 * 255)))]
					}
				)
			}
			else {
				WaveformView(
					data: waveform.loudness.map { CGFloat($0) },
					color: waveform.pitch.map { gradient[Int($0 * 255)] }
				)
			}
		}
	}
}

struct WaveformView_Previews: PreviewProvider {
    static var previews: some View {
		WaveformView(
			data: (0...80).map {
				(sin(CGFloat($0) / 3) + 1) / 2
			},
			color: (0...80).map {
				Gradients.pitch[Int((sin(CGFloat($0) / 2) + 1) / 2 * 255)]
			}
		)
    }
}
