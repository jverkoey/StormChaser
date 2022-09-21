//
//  Model.swift
//  StormerChaserCatalyst
//
//  Created by Jeff Verkoeyen on 9/10/22.
//

import Foundation
import HurricaneDB
import SQLite

final class Model {
  private var db: Connection?
  var playlists: [Playlist] = []
  private var playlistMap: [Int64: Playlist] = [:]
  private var mediaItemMap: [Int64: MediaItem] = [:]

  var canAccessAppleMusic: Bool? = nil

  var url: URL? {
    didSet {
      if let url = url {
        let db = try! Connection(url.appendingPathComponent("hurricane.sqlite3").path)
        self.db = db
        (playlists, playlistMap) = Model.buildPlaylists(db: db)
      } else {
        db = nil
        playlists = []
      }
    }
  }

  func items(in playlist: Playlist) -> [MediaItem] {
    guard let db = db else {
      return []
    }

    let playlistOrder: [Int64]

    if !playlist.items.isEmpty {
      playlistOrder = playlist.items.components(separatedBy: ",").map { Int64(bitPattern: UInt64($0, radix: 16)!) }
    } else {
      playlistOrder = []
    }

    var artistNames: [Int64: String] = [:]

    let itemMap: [Int64: MediaItem] = try! db.prepare(
      MediaItemTable.table
        .select(
          MediaItemTable.id,
          MediaItemTable.title,
          MediaItemTable.artistId,
          MediaItemTable.grouping,
          MediaItemTable.rating,
          MediaItemTable.ratingComputed,
          MediaItemTable.location
        )
        .where( playlistOrder.contains(MediaItemTable.id) )
    ).reduce(into: [:], { partialResult, row in
      let artistName: String?
      if let artistId = row[MediaItemTable.artistId] {
        if let name = artistNames[artistId] {
          artistName = name
        } else if let artist = try db.pluck(ArtistTable.table.select(ArtistTable.name).where(ArtistTable.id == artistId)) {
          artistName = artist[ArtistTable.name]
          artistNames[artistId] = artistName
        } else {
          artistName = nil
        }
      } else {
        artistName = nil
      }

      let url: URL?
      if let location = row[MediaItemTable.location] {
        url = URL(string: location)!
      } else {
        url = nil
      }
      partialResult[row[MediaItemTable.id]] = MediaItem(
        id: row[MediaItemTable.id],
        title: row[MediaItemTable.title],
        grouping: row[MediaItemTable.grouping],
        url: url
      )
    })

    mediaItemMap.merge(itemMap) { _, new in new }

    return playlistOrder.map { itemMap[$0]! }
  }
}

// MARK: - Playlists

extension Model {

  func playlist(withId id: Int64) -> Playlist? {
    return playlistMap[id]
  }

  func mediaItem(withId id: Int64) -> MediaItem? {
    return mediaItemMap[id]
  }

  func moveItem(id: Int64, fromIndex: Int, toIndex: Int, in playlist: Playlist) {
    assert(!playlist.items.isEmpty)
    var playlistItems = playlist.items.components(separatedBy: ",")
    playlistItems.swapAt(fromIndex, toIndex)
    let items = playlistItems.joined(separator: ",")

    if url!.startAccessingSecurityScopedResource() {
      let selector = PlaylistsTable.table.filter(PlaylistsTable.id == playlist.id)
      try! db!.run(selector.update(PlaylistsTable.items <- items))
      (playlists, playlistMap) = Model.buildPlaylists(db: db!)
      url!.stopAccessingSecurityScopedResource()
    }
  }

  func movePlaylist(_ playlist: Playlist, into destinationPlaylist: Playlist) {
    if url!.startAccessingSecurityScopedResource() {
      let selector = PlaylistsTable.table.filter(PlaylistsTable.id == playlist.id)
      try! db!.run(selector.update(PlaylistsTable.parentId <- destinationPlaylist.id))
      (playlists, playlistMap) = Model.buildPlaylists(db: db!)
      url!.stopAccessingSecurityScopedResource()
    }
  }

  func setPlaylist(_ playlist: Playlist, name: String) {
    if url!.startAccessingSecurityScopedResource() {
      let selector = PlaylistsTable.table.filter(PlaylistsTable.id == playlist.id)
      try! db!.run(selector.update(PlaylistsTable.name <- name))
      (playlists, playlistMap) = Model.buildPlaylists(db: db!)
      url!.stopAccessingSecurityScopedResource()
    }
  }

  private static func buildPlaylists(db: Connection) -> ([Playlist], [Int64: Playlist]) {
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
    return (
      Array(playlistMap.values).filter { $0.parentId == nil }.sorted(by: playlistSortComparator),
      playlistMap
    )
  }
}

private func playlistSortComparator(playlist1: Playlist, playlist2: Playlist) -> Bool {
  if (playlist1.children == nil) == (playlist2.children == nil) {
    return playlist1.name < playlist2.name
  }
  return playlist1.children != nil
}
