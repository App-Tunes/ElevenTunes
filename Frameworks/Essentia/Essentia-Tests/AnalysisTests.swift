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
	
    func testScale() throws {
		let testBundle = Bundle(for: Self.self)
		guard let fileUrl = testBundle.url(forResource: "445632__djfroyd__c-major-scale", withExtension: "wav")
		  else { fatalError() }
		
		let file = EssentiaFile(url: fileUrl)
		let analysis = try file.analyze()
		let keyAnalysis = analysis.keyAnalysis!
		
		XCTAssertEqual(keyAnalysis.key, "C")
		XCTAssertEqual(keyAnalysis.scale, "major")
		XCTAssertEqual(keyAnalysis.tuningFrequency, 440, accuracy: 1)
    }
}
