//
//  Model.swift
//  StormerChaserCatalyst
//
//  Created by Jeff Verkoeyen on 9/10/22.
//

import Foundation
import HurricaneDB
import SQLite

final class Playlist: Equatable, Identifiable, Hashable {
  internal init(id: Int64, parentId: Int64?, name: String, items: String, children: [Playlist]? = nil) {
    self.identifier = id
    self.parentId = parentId
    self.name = name
    self.items = items
    self.children = children
  }

  let identifier: Int64
  let parentId: Int64?
  let name: String
  let items: String
  var children: [Playlist]? = nil

  var isFolder: Bool { children != nil }

  static func == (lhs: Playlist, rhs: Playlist) -> Bool {
    lhs === rhs
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(identifier)
  }
}

final class Model {
  private var db: Connection?
  var playlists: [Playlist] = []

  var url: URL? {
    didSet {
      if let url = url {
        let db = try! Connection(url.path)
        self.db = db
        playlists = Model.buildPlaylists(db: db)
      } else {
        db = nil
        playlists = []
      }
    }
  }

  private static func buildPlaylists(db: Connection) -> [Playlist] {
    // Build an in-memory map of id->playlist.
    var playlistMap: [Int64: Playlist] = [:]
    for row in try! db.prepare(PlaylistsTable.table
      .select(PlaylistsTable.id,
              PlaylistsTable.name,
              PlaylistsTable.parentId,
              PlaylistsTable.items
             )) {
      playlistMap[row[PlaylistsTable.id]] = Playlist(
        id: row[PlaylistsTable.id],
        parentId: row[PlaylistsTable.parentId],
        name: row[PlaylistsTable.name],
        items: row[PlaylistsTable.items]
      )
    }

    // Connect each playlist to its parent.
    for playlist in playlistMap.values {
      guard let parentId = playlist.parentId else {
        continue
      }
      let parent = playlistMap[parentId]!
      if parent.children == nil {
        parent.children = []
      }
      parent.children?.append(playlist)
    }

    // Sort all of the playlists first by whether they are a folder, and second by name.
    for playlist in playlistMap.values {
      playlist.children?.sort(by: playlistSortComparator)
    }
    return Array(playlistMap.values).filter { $0.parentId == nil }.sorted(by: playlistSortComparator)
  }
}

private func playlistSortComparator(playlist1: Playlist, playlist2: Playlist) -> Bool {
  if (playlist1.children == nil) == (playlist2.children == nil) {
    return playlist1.name < playlist2.name
  }
  return playlist1.children != nil
}
