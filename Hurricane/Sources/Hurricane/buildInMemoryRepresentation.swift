import Foundation
import HurricaneDB
import iTunesXML
import SQLite

func buildInMemoryRepresentation(db: Connection) throws -> ITunesLibrary {
  var nextId: Int = 1

  var tracks: [Int: ITunesTrack] = [:]
  var artistNames: [Int64: String] = [:]
  var persistentTrackIdToId: [Int64: Int] = [:]

  var albums: [Int64: (discNumber: Int?, rating: Int?, ratingComputed: Bool)] = [:]

  print("Building in-memory representation of the itunes library...")
  print("- Fetching all tracks...")
  for item in try db.prepare(MediaItemTable.table
    .select(MediaItemTable.id,
            MediaItemTable.title,
            MediaItemTable.artistId,
            MediaItemTable.composer,
            MediaItemTable.kind,
            MediaItemTable.fileSize,
            MediaItemTable.totalTime,
            MediaItemTable.albumId,
            MediaItemTable.trackNumber,
            MediaItemTable.rating,
            MediaItemTable.grouping,
            MediaItemTable.ratingComputed,
            MediaItemTable.year,
            MediaItemTable.beatsPerMinute,
            MediaItemTable.modifiedDate,
            MediaItemTable.addedDate,
            MediaItemTable.bitrate,
            MediaItemTable.sampleRate,
            MediaItemTable.comments,
            MediaItemTable.volumeNormalizationEnergy,
            MediaItemTable.location,
            MediaItemTable.kind
           )
  ) {
    // Will be needed later when writing out playlists.
    persistentTrackIdToId[item[MediaItemTable.id]] = nextId

    let artistName: String?
    if let artistId = item[MediaItemTable.artistId] {
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

    let discNumber: Int?
    let albumRating: Int?
    let albumRatingComputed: Bool
    let albumId = item[MediaItemTable.albumId]
    if let album = albums[albumId] {
      discNumber = album.discNumber
      albumRating = album.rating
      albumRatingComputed = album.ratingComputed
    } else if let artist = try db.pluck(AlbumTable.table.select(AlbumTable.discNumber, AlbumTable.rating, AlbumTable.ratingComputed).where(AlbumTable.id == albumId)) {
      discNumber = Int(artist[AlbumTable.discNumber])
      albumRating = Int(artist[AlbumTable.rating])
      albumRatingComputed = artist[AlbumTable.ratingComputed]
      albums[albumId] = (discNumber: discNumber, rating: albumRating, ratingComputed: albumRatingComputed)
    } else {
      discNumber = nil
      albumRating = nil
      albumRatingComputed = false
    }

    tracks[nextId] = ITunesTrack(
      trackID: nextId,
      name: item[MediaItemTable.title],
      artist: artistName,
      composer: item[MediaItemTable.composer],
      grouping: item[MediaItemTable.grouping],
      kind: item[MediaItemTable.kind] ?? "MPEG audio file",
      size: Int(item[MediaItemTable.fileSize]),
      totalTime: Int(item[MediaItemTable.totalTime]),
      discNumber: discNumber,
      trackNumber: Int(item[MediaItemTable.trackNumber]),
      year: Int(item[MediaItemTable.year]),
      bpm: Int(item[MediaItemTable.beatsPerMinute]),
      dateModified: item[MediaItemTable.modifiedDate],
      dateAdded: item[MediaItemTable.addedDate] ?? Date.now,
      bitRate: Int(item[MediaItemTable.bitrate]),
      sampleRate: Int(item[MediaItemTable.sampleRate]),
      comments: item[MediaItemTable.comments],
      albumRating: albumRating,
      albumRatingComputed: albumRatingComputed,
      normalization: Int(item[MediaItemTable.volumeNormalizationEnergy]),
      persistentID: String(format: "%ll016X", item[MediaItemTable.id]),
      trackType: item[MediaItemTable.kind] ?? "",
      location: item[MediaItemTable.location] ?? "",
      fileFolderCount: -1,
      libraryFolderCount: -1,
      rating: Int(item[MediaItemTable.rating]),
      ratingComputed: item[MediaItemTable.ratingComputed]
    )

    nextId += 1
  }

  var playlistPersistentIdToId: [Int64: Int] = [:]
  var playlistPersistentIdsWithChildren = Set<String>()

  print("- Fetching all playlists...")
  var playlists: [ITunesPlaylist] = []
  for item in try db.prepare(PlaylistsTable.table
    .select(PlaylistsTable.id,
            PlaylistsTable.name,
            PlaylistsTable.master,
            PlaylistsTable.parentId,
            PlaylistsTable.items
           )
  ) {
    playlistPersistentIdToId[item[PlaylistsTable.id]] = nextId

    let parentPersistentId: String?
    if let parentId = item[PlaylistsTable.parentId] {
      let id = String(format: "%ll016X", UInt64(bitPattern: parentId))
      parentPersistentId = id
      playlistPersistentIdsWithChildren.insert(id)
    } else {
      parentPersistentId = nil
    }

    let playlistItems: [ITunesPlaylistItem]
    if !item[PlaylistsTable.items].isEmpty {
      playlistItems = item[PlaylistsTable.items].components(separatedBy: ",").map {
        guard let persistentId = UInt64($0, radix: 16) else {
          fatalError("Failed to parse integer \($0)")
        }
        return ITunesPlaylistItem(trackID: persistentTrackIdToId[Int64(bitPattern: persistentId)]!)
      }
    } else {
      playlistItems = []
    }

    playlists.append(ITunesPlaylist(
      name: item[PlaylistsTable.name],
      description: "",
      master: item[PlaylistsTable.master],
      playlistID: nextId,
      playlistPersistentID: String(format: "%ll016X", UInt64(bitPattern: item[PlaylistsTable.id])),
      parentPersistentID: parentPersistentId,
      visible: !item[PlaylistsTable.master],
      allItems: true,
      folder: true,
      playlistItems: playlistItems
    ))

    nextId += 1
  }

  print("- Creating iTunes library object...")
  return ITunesLibrary(
    majorVersion: 1,
    minorVersion: 1,
    date: Date.now,
    applicationVersion: "1.3.0.117",
    features: 5,
    showContentRatings: true,
    musicFolder: "file:///Users/featherless/Music/iTunes/Media.localized/",
    libraryPersistentID: "6D0977E01EAF3C87",
    tracks: tracks, playlists: playlists,
    playlistPersistentIdsWithChildren: playlistPersistentIdsWithChildren
  )
}
