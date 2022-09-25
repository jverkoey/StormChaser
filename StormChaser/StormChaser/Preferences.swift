//
//  Preferences.swift
//  StormChaser
//
//  Created by Jeff Verkoeyen on 9/24/22.
//

import Foundation

enum TagExportMode: String, Codable, CaseIterable, Identifiable {
  case none
  case grouping
  var id: Self { self }
}

struct Preferences: Codable {
  var tagExportMode: TagExportMode
}
