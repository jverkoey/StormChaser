//
//  Playlist.swift
//  StormerChaserCatalyst
//
//  Created by Jeff Verkoeyen on 9/10/22.
//

import Foundation

// TODO: Need to find a way to ensure that playlist data can be mutated and invalidated properly
// throughout the app so that views aren't holding on to stale instances of a given view.
final class Playlist: Equatable, Identifiable, Hashable {
  internal init(id: Int64, parentId: Int64?, name: String, items: String, children: [Playlist]? = nil) {
    self.id = id
    self.parentId = parentId
    self.name = name
    self.items = items
    self.children = children
  }

  let id: Int64
  let parentId: Int64?
  let name: String
  let items: String
  var children: [Playlist]? = nil

  var isFolder: Bool { children != nil }

  static func == (lhs: Playlist, rhs: Playlist) -> Bool {
    lhs === rhs
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}
