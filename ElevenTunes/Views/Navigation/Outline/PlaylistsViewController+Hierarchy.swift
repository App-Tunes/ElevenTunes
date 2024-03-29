//
//  PlaylistsViewController+Hierarchy.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 14.02.21.
//

import Foundation
import Combine
import TunesUI

extension PlaylistsViewController {
	func childrenUpdated(ofItem item: Item, from: [Item]?, to: [Item]?) {
		let item = item == directoryItem ? nil : item
		
		ListTransition.findBest(before: from, after: to)
			.executeAnimationsInOutlineView(outlineView, childrenOf: item)
	}
	
	class Item: Identifiable, Hashable {
		let playlist: AnyPlaylist
		weak var parent: Item?
		
		weak var delegate: PlaylistsViewController?
		
		var observer: AnyCancellable? = nil
		var childrenState: PlaylistAttributes.ValueSnapshot<[Item]> {
			didSet {
				delegate?.childrenUpdated(ofItem: self, from: oldValue.value, to: childrenState.value)
			}
		}

		var demand: AnyCancellable? = nil

		init(playlist: AnyPlaylist, parent: Item?, delegate: PlaylistsViewController) {
			self.playlist = playlist
			self.parent = parent
			
			self.delegate = delegate

			self.childrenState = .missing([])
			
			self.observer = playlist.attribute(PlaylistAttribute.children)
				.onMain()
				.sink { [weak self] in
					guard let self = self, let delegate = self.delegate else {
						return
					}
					
					setIfDifferent(self, \.childrenState, $0.map { $0.map {
						Item(playlist: $0, parent: self, delegate: delegate)
					} })
				}
		}
		
		var isDemanding: Bool {
			get { demand != nil }
			set {
				demand = newValue ? playlist.demand([.children]) : nil
			}
		}
		
		var id: String { playlist.id }
		
		func hash(into hasher: inout Hasher) {
			hasher.combine(playlist.id)
		}
		
		static func == (lhs: PlaylistsViewController.Item, rhs: PlaylistsViewController.Item) -> Bool {
			lhs.id == rhs.id
		}
	}
}
