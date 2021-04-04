//
//  FileDatabase.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 04.04.21.
//

import Foundation

class ImageDatabase<ID: CustomStringConvertible> {
	enum ReadError: Error {
		case noDatabase
		case notAnImage
		case cannotResize
		case cannotWrite
	}
	
	// TODO Should be URL, and re-create DB on changes. Harder to implement tho
	let urlProvider: () -> URL?
	let size: (Int, Int)
	
	init(urlProvider: @escaping () -> URL?, size: (Int, Int)) {
		self.urlProvider = urlProvider
		self.size = size
	}
	
	func url(for id: ID) throws -> URL {
		let baseURL = try urlProvider().unwrap(orThrow: ReadError.noDatabase)
		try FileManager.default.createDirectory(at: baseURL, withIntermediateDirectories: true)
		
		return baseURL
			.appendingPathComponent(id.description)
			.appendingPathExtension(".png")
	}
	
	func toData(_ image: NSImage) throws -> Data {
		guard let bitmapRep = NSBitmapImageRep(
			bitmapDataPlanes: nil, pixelsWide: size.0, pixelsHigh: size.1,
			bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
			colorSpaceName: .calibratedRGB, bytesPerRow: 0, bitsPerPixel: 0),
			let context = NSGraphicsContext(bitmapImageRep: bitmapRep)
		else {
			throw ReadError.cannotResize
		}
		
		let newSize = NSMakeSize(CGFloat(size.0), CGFloat(size.1))
		bitmapRep.size = newSize
		
		NSGraphicsContext.current = context
		image.draw(in: NSRect(x: 0, y: 0, width: newSize.width, height: newSize.height), from: .zero, operation: .copy, fraction: 1.0)

		return try bitmapRep.representation(using: .png, properties: [:])
			.unwrap(orThrow: ReadError.cannotWrite)
	}
	
	func fromData(_ data: Data) throws -> NSImage {
		try NSImage(data: data).unwrap(orThrow: ReadError.notAnImage)
	}
	
	func get(_ id: ID) throws -> NSImage {
		try NSImage(contentsOf: url(for: id)).unwrap(orThrow: ReadError.notAnImage)
	}
	
	func insert(_ image: NSImage, for id: ID) throws {
		try toData(image).write(to: url(for: id))
	}
}
