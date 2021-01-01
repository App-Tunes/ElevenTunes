//
//  RemoteImageCollection.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 01.01.21.
//

import Foundation
import AppKit
import Combine

protocol RemoteImageCollectionDelegate: AnyObject {
    func url(for feature: RemoteImageCollection.Feature) -> AnyPublisher<URL?, Error>
}

class RemoteImageCollection {
    enum RemoteError: Error {
        case noURL, notAnImage
    }

    public struct Feature: OptionSet, Hashable {
        public let rawValue: Int16
        
        public init(rawValue: Int16) {
            self.rawValue = rawValue
        }
        
        public static let preview      = Feature(rawValue: 1 << 0)
    }
        
    weak var delegate: RemoteImageCollectionDelegate?

    let featureSet = FeatureSet<Feature, Feature>()

    var previewRequest: AnyCancellable?
    var preview: CurrentValueSubjectPublishingDemand<NSImage?, Never> = .init(nil)
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        mergeDemandMask(
            Feature(), subjects: [
                (preview.$demand, .preview)
            ]
        ).combineLatest(featureSet.$features)
        .map { $0.subtracting($1) }
        .removeDuplicates()
        // Only load images if we really need to after 500ms
        .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
        .sink { [weak self] in
            self?.load(images: $0)
        }.store(in: &cancellables)
    }
    
    public func load(images mask: Feature) {
        featureSet.promise(mask) { promise in
            if promise.includes(.preview) {
                previewRequest = delegate?.url(for: .preview)
                    .removeDuplicates()
                    .tryMap { try $0.unwrap(orThrow: RemoteError.noURL) }
                    .flatMap { (url: URL) -> AnyPublisher<Data, Error> in
                        URLSession.shared.dataTaskPublisher(for: url)
                            .map { (data, response) in data }
                            .eraseError()
                            .eraseToAnyPublisher()
                    }
                    .tryMap { try NSImage(data: $0).unwrap(orThrow: RemoteError.notAnImage) }
                    .fulfillingAny(.preview, of: promise)
                    .sink { [weak self] result in
                        switch result {
                        case .success(let image):
                            self?.preview.value = image
                        case .failure(_):
                            self?.preview.value = nil
                        }
                    }
            }
        }
    }
}
