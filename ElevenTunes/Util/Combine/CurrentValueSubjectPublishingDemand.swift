//
//  DemandPublisher.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 30.12.20.
//

import Foundation
import Combine

/// Behaves like a CurrentValueSubject, but exposes an @Published current demand,
/// as determined by the maximum of the subscriber's demands. This is useful when needing
/// to manually publish latest values into this subject, but only when there's demand.
public class CurrentValueSubjectPublishingDemand<Output, Failure: Error>: Subject {
    private let demandLock = NSLock()
    private let subscriberLock = NSLock()

    private(set) var subscriptions = Set<CSubscription>()
    
    /// The current maximum demand by any active subscriber
    @Published private(set) public var demand: Subscribers.Demand = .none
    
    public var value: Output {
        didSet { _send(value) }
    }
    
    init(_ initialValue: Output) {
        value = initialValue
    }

    public func send(_ value: Output) {
        self.value = value
    }

    public func _send(_ value: Output) {
        // Only push to those that currently have a demand,
        // as requested by Swift API
        let requests: [CSubscription] = demandLock.perform {
            guard demand > .none else { return [] }
            
            demand -= 1
            return subscriptions.filter {
                let isPositive = $0.demand > .none
                $0.demand -= 1
                return isPositive
            }
        }
        
        requests.forEach {
            _ = $0.downstream.receive(value)
        }
    }
    
    public func send(completion: Subscribers.Completion<Failure>) {
        let subscriptions: Set<CSubscription> = subscriberLock.perform {
            let previous = self.subscriptions
            self.subscriptions.removeAll()
            return previous
        }

        subscriptions.forEach {
            $0.downstream.receive(completion: completion)
        }
        
        demandLock.perform { demand = .none }
    }
    
    public func send(subscription: Subscription) {
        // We can only request once, so let's make it unlimited :/
        subscription.request(.unlimited)
    }
    
    public func receive<S>(subscriber: S) where S : Subscriber, Failure == S.Failure, Output == S.Input {
        let subscription = CSubscription(subject: self, downstream: AnySubscriber(subscriber))
        
        subscriberLock.perform {
            _ = subscriptions.insert(subscription)
        }
        subscriber.receive(subscription: subscription)
    }
}

extension CurrentValueSubjectPublishingDemand {
    public class CSubscription: Combine.Subscription, Hashable {
        var demand: Subscribers.Demand = .none
        
        var upstream: Subscription? = nil
        let downstream: AnySubscriber<Output, Failure>
        // Optional to avoid setting anything when we're dead
        weak var subject: CurrentValueSubjectPublishingDemand<Output, Failure>?

        init(subject: CurrentValueSubjectPublishingDemand<Output, Failure>, downstream: AnySubscriber<Output, Failure>) {
            self.downstream = downstream
            self.subject = subject
        }

        public func request(_ d: Subscribers.Demand) {
            if d > .none, let subject = subject {
                // Push one value to the subject.
                // Since we're a current value subject, we won't push more until
                // a new demand.
                let newDemand = downstream.receive(subject.value)
                
                subject.demandLock.perform {
                    demand += d + newDemand - 1
                    if demand > subject.demand {
                        subject.demand = demand
                    }
                }
            }
            
            upstream?.request(d)
        }
        
        public func cancel() {
            if let subject = subject {
                subject.subscriberLock.perform {
                    _ = subject.subscriptions.remove(self)
                    self.subject = nil
                }

                subject.demandLock.perform {
                    // If we were (one of) the highest demanders,
                    // recalculate demand to new max
                    if demand >= subject.demand {
                        subject.demand = subject.subscriptions
                            .map(\.demand).max() ?? .none
                    }
                }
            }
        }
        
        public func hash(into hasher: inout Hasher) {
            hasher.combine(combineIdentifier)
        }
        
        public static func == (lhs: CSubscription, rhs: CSubscription) -> Bool {
            lhs.combineIdentifier == rhs.combineIdentifier
        }
    }
}

func mergeDemandMask<Set>(_ initialValue: Set, subjects: [(Published<Subscribers.Demand>.Publisher, Set)]) -> AnyPublisher<Set, Never> where Set: SetAlgebra {
    subjects
        // Combine demand publishers
        .map { (demand, mask) in
            demand.map {
                ($0, mask)
            }
        }
        .combineLatest()
        // Combine masks
        .map {
            $0.compactMap { (demand, mask) in
                (demand > 0) ? mask : nil
            }.reduce(initialValue) { $0.union($1) }
        }
        .eraseToAnyPublisher()
}
