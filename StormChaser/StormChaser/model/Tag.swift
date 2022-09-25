//
//  Tag.swift
//  StormChaser
//
//  Created by Jeff Verkoeyen on 9/24/22.
//

import Foundation

final class Tag: Equatable, Identifiable, Hashable {
  internal init(id: Int64, name: String) {
    self.id = id
    self.name = name
  }

  let id: Int64
  let name: String

  static func == (lhs: Tag, rhs: Tag) -> Bool {
    lhs.id == rhs.id
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}
