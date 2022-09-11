//
//  MediaItem.swift
//  StormerChaserCatalyst
//
//  Created by Jeff Verkoeyen on 9/10/22.
//

import Foundation

final class MediaItem: Equatable, Identifiable, Hashable {
  internal init(id: Int64, title: String, grouping: String?) {
    self.id = id
    self.title = title
    self.grouping = grouping
  }

  let id: Int64
  let title: String
  let grouping: String?

  static func == (lhs: MediaItem, rhs: MediaItem) -> Bool {
    lhs === rhs
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}
