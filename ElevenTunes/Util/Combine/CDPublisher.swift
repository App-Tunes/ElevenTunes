//
//  CDPublisher.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 26.12.20.
//

import Foundation

import Combine
import CoreData
import Foundation

// from https://stackoverflow.com/a/60535155/730797
class CDPublisher<Entity>: NSObject, NSFetchedResultsControllerDelegate, Publisher where Entity: NSManagedObject {
    typealias Output = [Entity]
    typealias Failure = Error

    private let request: NSFetchRequest<Entity>
    private let context: NSManagedObjectContext
    private let subject: CurrentValueSubject<[Entity], Failure>
    private var resultController: NSFetchedResultsController<NSManagedObject>?
    private var subscriptions = 0

    private let lock = NSLock()
    
    init(request: NSFetchRequest<Entity>, context: NSManagedObjectContext) {
        if request.sortDescriptors == nil { request.sortDescriptors = [] }
        self.request = request
        self.context = context
        subject = CurrentValueSubject([])
        super.init()
    }

    func receive<S>(subscriber: S) where S: Subscriber, CDPublisher.Failure == S.Failure, CDPublisher.Output == S.Input {
        var start = false

        lock.lock()
        subscriptions += 1
        start = subscriptions == 1

        if start {
            let controller = NSFetchedResultsController(fetchRequest: request, managedObjectContext: context,
                                                        sectionNameKeyPath: nil, cacheName: nil)
            controller.delegate = self

            do {
                try controller.performFetch()
                let result = controller.fetchedObjects ?? []
                subject.send(result)
            } catch {
                subject.send(completion: .failure(error))
            }
            resultController = controller as? NSFetchedResultsController<NSManagedObject>
        }
        lock.unlock()
        
        CDSubscription(fetchPublisher: self, subscriber: AnySubscriber(subscriber))
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        let result = controller.fetchedObjects as? [Entity] ?? []
        subject.send(result)
    }

    private func dropSubscription() {
        lock.lock()
        subscriptions -= 1
        let stop = subscriptions == 0

        if stop {
            resultController?.delegate = nil
            resultController = nil
        }
        lock.unlock()
    }

    private class CDSubscription: Subscription {
        private var fetchPublisher: CDPublisher?
        private var cancellable: AnyCancellable?

        @discardableResult
        init(fetchPublisher: CDPublisher, subscriber: AnySubscriber<Output, Failure>) {
            self.fetchPublisher = fetchPublisher

            subscriber.receive(subscription: self)

            // TODO If not onMain, will crash. Why? Who knows!
            cancellable = fetchPublisher.subject.onMain()
                .sink(receiveCompletion: subscriber.receive, receiveValue: { _ = subscriber.receive($0)}
            )
        }

        func request(_ demand: Subscribers.Demand) {}

        func cancel() {
            guard cancellable != nil else {
                return  // Already dead
            }
            
            cancellable?.cancel()
            cancellable = nil
            fetchPublisher?.dropSubscription()
            fetchPublisher = nil
        }
    }

}
