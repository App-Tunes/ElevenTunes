//
//  AnalysisTests.swift
//  Essentia-Tests
//
//  Created by Lukas Tenbrink on 28.03.21.
//  Copyright © 2021 ivorius. All rights reserved.
//

import XCTest

class AnalysisTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

	func testBadFile() throws {
		let file = EssentiaFile(url: URL(string: "/this/file/does/not/exist.aiff")!)
		XCTAssertThrowsError(try file.analyze()) { _ in
			// TODO Check for error type with XCTAssertEqual
		}
	}
	
	func testScaleAnalysis() throws {
		let testBundle = Bundle(for: Self.self)
		let fileUrl = testBundle.url(forResource: "445632__djfroyd__c-major-scale", withExtension: "wav")!
		
		let file = EssentiaFile(url: fileUrl)
		let analysis = try file.analyze()

		let keyAnalysis = analysis.keyAnalysis!
		XCTAssertEqual(keyAnalysis.key, "C")
		XCTAssertEqual(keyAnalysis.scale, "major")
		XCTAssertEqual(keyAnalysis.tuningFrequency, 440, accuracy: 1)

		let rhythmAnalysis = analysis.rhythmAnalysis!
		XCTAssertEqual(rhythmAnalysis.bpm, 121, accuracy: 1)
	}

	func testWaveform() throws {
		let testBundle = Bundle(for: Self.self)
		// Consists of 4 sections: Pling Silence Pling Silence
		let fileUrl = testBundle.url(forResource: "445632__djfroyd__c-major-scale", withExtension: "wav")!
		
		let file = EssentiaFile(url: fileUrl)
		let analysis = try file.analyzeWaveform(8)

		XCTAssertEqual(analysis.count, 8)

		XCTAssertEqual(analysis.loudness[0], analysis.loudness[1], accuracy: 1)
		XCTAssertEqual(analysis.loudness[3], analysis.loudness[4], accuracy: 1)
		XCTAssertNotEqual(analysis.loudness[0], analysis.loudness[2], accuracy: 1)

		XCTAssertGreaterThan(analysis.loudness[0], analysis.loudness[2])
		XCTAssertLessThan(analysis.loudness[2], analysis.loudness[4])
		XCTAssertGreaterThan(analysis.loudness[4], analysis.loudness[6])
		
		// Pitch
		XCTAssertLessThan(analysis.pitch[0], analysis.pitch[1])
		XCTAssertLessThan(analysis.pitch[4], analysis.pitch[5])
	}
}
