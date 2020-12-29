//
//  FeatureSet.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 29.12.20.
//

import Foundation
import Combine

/// A feature set is, first and foremost, a set of features that is multithreading-compatible.
/// Features may be blocked
///
/// - Example:
/// ```
/// let set = FeatureSet<MyOptionSet, MyOptionSet>()
/// set.blocking([.feature1, .feature2]) { promise in
///     promise.fulfilling(.feature1) { Thread.sleep(2) }
///     if promise.fulfill(.feature2) { print("Feature 2 was completed!") }
/// }
/// ````
class FeatureSet<Feature: Hashable, Set> where Set: SetAlgebra, Set.Element == Feature {
    private let lock = NSLock()
    
    @Published private(set) var features = Set()
    @Published private(set) var blocked = Set()

    func contains(_ key: Feature) -> Bool { lock.perform { features.contains(key) } }
    
    @discardableResult
    func promise(_ features: Set, during closure: (Promise) -> Void) -> Bool {
        lock.lock()
        let missing = features.subtracting(self.features.union(self.blocked))
        
        if missing.isEmpty {
            lock.unlock()
            return false
        }
        
        self.blocked.formUnion(missing)
        lock.unlock()

        let promise = Promise(parent: self, features: missing)
        closure(promise)
        
        lock.lock()
        self.blocked.subtract(promise.unfulfilledFeatures)
        lock.unlock()
        
        return true
    }
    
    fileprivate func mark(_ feature: Feature) {
        lock.perform {
            blocked.remove(feature)
            features.insert(feature)
        }
    }

    fileprivate func markAll(_ features: Set) {
        lock.perform {
            blocked.subtract(features)
            self.features.formUnion(features)
        }
    }
    
    fileprivate func unblock(_ feature: Feature) { lock.perform { blocked.remove(feature) } }
    fileprivate func unblockAll(_ features: Set) { lock.perform { blocked.subtract(features) } }

    func insert(_ feature: Feature) { lock.perform { _ = features.insert(feature) } }
    func formUnion(_ features: Set) { lock.perform { self.features.formUnion(features) } }
    
    func remove(_ feature: Feature) { lock.perform { _ = features.remove(feature) } }
    func subtract(_ features: Set) { lock.perform { self.features.subtract(features) } }
}

extension FeatureSet {
    class Promise {
        private let lock = NSLock()
        let parent: FeatureSet
        private(set) var unfulfilledFeatures: Set
        
        init(parent: FeatureSet, features: Set) {
            self.parent = parent
            self.unfulfilledFeatures = features
        }
        
        func canFulfill(_ feature: Feature) -> Bool {
            lock.perform { unfulfilledFeatures.contains(feature) }
        }
        
        func canFulfillAny(_ features: Set) -> Bool {
            lock.perform { !unfulfilledFeatures.isDisjoint(with: features) }
        }

        @discardableResult
        private func remove(_ feature: Feature) -> Bool {
            lock.perform { unfulfilledFeatures.remove(feature) != nil }
        }

        @discardableResult
        private func subtract(_ features: Set) -> Set {
            lock.perform {
                let subtracting = unfulfilledFeatures.intersection(features)
                unfulfilledFeatures.subtract(subtracting)
                return subtracting
            }
        }

        /// Fulfills the feature immediately
        @discardableResult
        func fulfill(_ feature: Feature) -> Bool {
            if remove(feature) {
                parent.mark(feature)
                return true
            }
            return false
        }

        /// Fulfills the features immediately
        @discardableResult
        func fulfillAny(_ features: Set) -> Set {
            let fulfilling = subtract(features)
            if !fulfilling.isEmpty { parent.markAll(fulfilling) }
            return fulfilling
        }
        
        /// Aborts the features from the promise
        @discardableResult
        func abandonAll(_ features: Set) -> Set {
            let abandoning = subtract(features)
            if !abandoning.isEmpty { parent.unblockAll(abandoning) }
            return abandoning
        }
        
        @discardableResult
        /// Calls the closure if the feature can be fulfilled
        func fulfilling(_ feature: Feature, during closure: () -> Void) -> Bool {
            let shouldFulfill = remove(feature)
            guard shouldFulfill else { return false }

            closure()
            parent.mark(feature)
            return true
        }

        @discardableResult
        /// Calls the closure if any of the features can be fulfilled
        func fulfillingAny(_ features: Set, during closure: () -> Void) -> Set {
            let fulfilling = subtract(features)
            if !fulfilling.isEmpty {
                closure()
                parent.markAll(features)
            }
            return fulfilling
        }

        /// Offloads fulfilling the feature to the cancellation of the return value
        func fulfillAnyLater(_ features: Set) -> Promise? {
            let fulfilling = subtract(features)
            guard !fulfilling.isEmpty else {
                return nil
            }

            return Promise(parent: parent, features: fulfilling)
        }
    }
}

extension FeatureSet: CustomStringConvertible where Set: CustomStringConvertible {
    var description: String { "FeatureSet(\(features)" }
}

extension FeatureSet.Promise: CustomStringConvertible where Set: CustomStringConvertible {
    var description: String { "Promise(\(unfulfilledFeatures)" }
}

extension Publisher {
    /// Fulfills the feature once the stream terminates
    func fulfillingAny<Feature: Hashable, Set>(_ features: Set, of promise: FeatureSet<Feature, Set>.Promise) -> Publishers.HandleEvents<Self> where Set: SetAlgebra, Set.Element == Feature {
        let later = promise.fulfillAnyLater(features)
        return handleTermination { success in
            if success { later?.fulfillAny(features) }
            else { later?.abandonAll(features) }
        }
    }
}
