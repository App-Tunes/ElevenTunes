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
	var waveform: Waveform
	@State var resampled: Waveform = Waveform(loudness: [], pitch: [])

	var body: some View {
		GeometryReader { geo in
			WaveformView(
				data:resampled.loudness.map { CGFloat($0) },
				color: resampled.pitch.map {
					$0.isFinite ? gradient[Int(round(max(0, min(1, $0)) * 255))] : .white
				}
			)
				.onReceive(
					Future.onQueue(.global(qos: .default)) { waveform }
				) { waveform in
					let samples = Int(geo.size.width / 4)
					guard self.waveform.count != samples else {
						return
					}
					
					let loudness = samples != waveform.count
						? ResampleToSize.best(data: waveform.loudness, toSize: samples)
						: waveform.loudness
					
					let pitch = samples != waveform.count
						? ResampleToSize.best(data: waveform.pitch, toSize: samples)
						: waveform.pitch

					DispatchQueue.main.async {
						self.resampled = Waveform(loudness: loudness, pitch: pitch)
					}
				}
		}
	}
}

struct ResamplingWaveformView_Previews: PreviewProvider {
    static var previews: some View {
		ResamplingWaveformView(
			gradient: Gradients.pitch, waveform: LibraryMock.waveform()
		)
			.frame(width: 500, height: 100)
    }
}
