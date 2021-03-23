//
//  ObservableBinding.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 24.03.21.
//

import Combine

class ObservableBinding<Value>: ObservableObject {
	private var observation: AnyCancellable?
	
	let get: () -> Value
	let set: (Value) -> Void
	
	init<T: ObservableObject>(_ object: T, value: ReferenceWritableKeyPath<T, Value>) {
		get = { object[keyPath: value] }
		set = { object[keyPath: value] = $0 }
		observation = object.objectWillChange.sink { [weak self] _ in
			self?.objectWillChange.send()
		}
	}
	
	var value: Value {
		get { get() }
		set { set(newValue) }
	}
}
