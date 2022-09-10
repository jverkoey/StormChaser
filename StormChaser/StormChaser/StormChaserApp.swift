//
//  StormChaserApp.swift
//  StormChaser
//
//  Created by Jeff Verkoeyen on 9/8/22.
//

import SwiftUI
import SQLite
import HurricaneDB

func getDocumentsDirectory() -> URL {
  let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
  let documentsDirectory = paths[0]
  return documentsDirectory
}

private final class Playlist: Equatable, Identifiable, Hashable {
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

  static func == (lhs: Playlist, rhs: Playlist) -> Bool {
    lhs === rhs
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(identifier)
  }
}

struct MediaItem: Hashable, Identifiable {
  let id: Int64
  let title: String
}

struct PlaylistView: SwiftUI.View {
  private let playlist: Playlist
  private let mediaItems: [MediaItem]
  @State private var selection: Int64?

  fileprivate init(playlist: Playlist, db: Connection) {
    self.playlist = playlist

    if !playlist.items.isEmpty {
      let playlistOrder = playlist.items.components(separatedBy: ",").map { Int64(bitPattern: UInt64($0, radix: 16)!) }

      let itemMap: [Int64: MediaItem] = try! db.prepare(
        MediaItemTable.table
          .select(MediaItemTable.id, MediaItemTable.title)
          .where( playlistOrder.contains(MediaItemTable.id) )
      ).reduce(into: [:], { partialResult, row in
        partialResult[row[MediaItemTable.id]] = MediaItem(
          id: row[MediaItemTable.id],
          title: row[MediaItemTable.title]
        )
      })

      self.mediaItems = playlistOrder.map { itemMap[$0]! }
    } else {
      self.mediaItems = []
    }
  }

  var body: some SwiftUI.View {
    Table(mediaItems, selection: $selection) {
      TableColumn("Title", value: \.title)
    }
  }
}

@main
struct StormChaserApp: App {
  private let documentsUrl = getDocumentsDirectory()
  private let db: Connection
  private let playlists: [Playlist]

  @State private var selection: Playlist?

  init() {
    self.db = try! Connection(documentsUrl.appendingPathComponent("hurricane.sqlite3").absoluteString)

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
    for playlist in playlistMap.values {
      playlist.children?.sort(by: { playlist1, playlist2 in
        if (playlist1.children == nil) == (playlist2.children == nil) {
          return playlist1.name < playlist2.name
        }
        return playlist1.children != nil
      })
    }
    self.playlists = Array(playlistMap.values).filter { $0.parentId == nil }.sorted(by: { playlist1, playlist2 in
      if (playlist1.children == nil) == (playlist2.children == nil) {
        return playlist1.name < playlist2.name
      }
      return playlist1.children != nil
    })
  }

  var body: some Scene {
    WindowGroup {
      NavigationView {
        // List must be keyed by .self in order for selection to persist.
        List(playlists, id: \.self, children: \.children, selection: $selection) { playlist in
          Text(playlist.name)
        }
        .listStyle(.sidebar)
        if let selection = self.selection {
          PlaylistView(playlist: selection, db: db)
        } else {
          Text("Pick a playlist")
        }
      }
    }
  }
}
