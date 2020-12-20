//
//  Preload.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 19.12.20.
//

import Foundation
import Combine

class Preload<Output, Failure: Error> {
    enum Result {
        case success(value: Output)
        case error(error: Error)
    }
    
    private var job: AnyCancellable { _job! }
    private var _job: AnyCancellable?
    let lock = NSLock()
    
    var result: Result? {
        didSet {
            if let result = result {
                receiver?(result)
            }
        }
    }
    
    var receiver: ((Result) -> Void)?

    init(_ future: Future<Output, Failure>) {
        self._job = future.sink(receiveCompletion: { completion in
            switch completion {
            case .failure(let error):
                self.lock.lock()
                self.result = .error(error: error)
                self.lock.unlock()
            default:
                break
            }
        }, receiveValue: { value in
            self.lock.lock()
            self.result = .success(value: value)
            self.lock.unlock()
        })
    }
    
    func acquire(ifLater: (() -> Void)? = nil, _ receiver: @escaping (Result) -> Void) {
        lock.lock()
        self.receiver = receiver
        if let result = result {
            receiver(result)
        }
        else {
            ifLater?()
        }
        lock.unlock()
    }
    
    func cancel() {
        job.cancel()
    }
}

extension Future {
    func preload() -> Preload<Output, Failure> {
        return Preload(self)
    }
}
