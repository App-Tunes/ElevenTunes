//
//  ContentInterpreter.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 23.12.20.
//

import Foundation
import Combine
import Cocoa
import UniformTypeIdentifiers

class ContentInterpreter<Interpreted> {
    enum InterpretationError: Error {
        case invalidData
    }
    
    typealias Interpreter = (URL) throws -> Interpreted?
	
	var types: [UTType] { [] }
    
    var interpreters: [Interpreter] = []
    
	func register(_ interpreter: @escaping Interpreter) {
		interpreters.append(interpreter)
	}

	func register(matches: @escaping (URL) throws -> Bool, interpret: @escaping (URL) throws -> Interpreted) {
		register { ((try? matches($0)) ?? false) ? try interpret($0) : nil }
	}

    func compactInterpret(urls: [URL]) -> [Interpreted] {
		urls.compactMap { try? self.interpret(url: $0) }
    }
    
    func interpret(url: URL) throws -> Interpreted? {
		try interpreters.compactMap {
			try $0(url)
		}.first
    }
    
    func interpret(_ item: NSSecureCoding, type: UTType) throws -> Interpreted? {
        if type == .fileURL || type == .url {
            guard
                let data = item as? Data, let url = URL(dataRepresentation: data, relativeTo: nil)
            else {
                throw InterpretationError.invalidData
            }

            return try interpret(url: url)
        }
        else {
            fatalError()
        }
    }
}
