//
//  CountdownText.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 02.04.21.
//

import SwiftUI

extension TimeInterval {
	var humanReadableText: String {
		let totalSeconds = Int(rounded())
		let hours: Int = Int(totalSeconds / 3600)
		
		let minutes: Int = Int(totalSeconds % 3600 / 60)
		let seconds: Int = Int((totalSeconds % 3600) % 60)

		if hours > 0 {
			return String(format: "%i:%02i:%02i", hours, minutes, seconds)
		} else {
			return String(format: "%i:%02i", minutes, seconds)
		}
	}
}

struct CountdownText: View {
	let referenceDate: Date
	let advancesAutomatically: Bool
	
	@State var currentDate: Date
	var timer: Timer? {
		advancesAutomatically ? Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
			self.currentDate = Date()
		} : nil
	}

    var body: some View {
		Text(abs(referenceDate.timeIntervalSince(currentDate)).humanReadableText)
			.onAppear(perform: {
				let _ = self.timer
			})
    }
}

struct CountdownText_Previews: PreviewProvider {
    static var previews: some View {
        CountdownText(
			referenceDate: Date().advanced(by: 10), advancesAutomatically: true, currentDate: Date()
		)
			.frame(width: 60, height: 15)
    }
}
