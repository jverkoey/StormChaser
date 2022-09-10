import Foundation
import SQLite
import HurricaneDB
import iTunesXML

func writeDatabaseToITunesXML(db: Connection, path: String = "/Users/featherless/Documents/Library.xml", trackFilter: (ITunesTrack) -> Bool) throws {
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
  let library = ITunesLibrary(
    majorVersion: 1,
    minorVersion: 1,
    date: Date.now,
    applicationVersion: "1.3.0.117",
    features: 5,
    showContentRatings: true,
    musicFolder: "file:///Users/featherless/Music/iTunes/Media.localized/",
    libraryPersistentID: "6D0977E01EAF3C87",
    tracks: tracks, playlists: playlists
  )

//  var trackFilter = Set<String>()
//  trackFilter.insert("3A9137968015D01B")
//  trackFilter.insert("1ED794A8A3EF5C92")
//  var trackIdFilter = Set<Int>()

  print("Writing XML...")
  let dateFormatter = DateFormatter()
  dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
  var output = """
  <?xml version="1.0" encoding="UTF-8"?>
  <!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
  <plist version="1.0">
  <dict>
  \t<key>Major Version</key><integer>\(library.majorVersion)</integer>
  \t<key>Minor Version</key><integer>\(library.minorVersion)</integer>
  \t<key>Date</key><date>\(dateFormatter.string(from: library.date))</date>
  \t<key>Application Version</key><string>\(library.applicationVersion)</string>
  \t<key>Features</key><integer>\(library.features)</integer>
  \t<key>Show Content Ratings</key><\(library.showContentRatings)/>
  \t<key>Music Folder</key><string>\(library.musicFolder)</string>
  \t<key>Library Persistent ID</key><string>\(library.libraryPersistentID)</string>
  \t<key>Tracks</key>
  \t<dict>
  """

  print("Writing tracks...")
  for id in library.tracks.keys.sorted() {
    let track = library.tracks[id]!
    if !trackFilter(track) {
      continue
    }

    output += """

  \t\t<key>\(id)</key>
  \t\t<dict>
  \t\t\t<key>Track ID</key><integer>\(track.trackID)</integer>
  \t\t\t<key>Name</key><string>\(CFXMLCreateStringByEscapingEntities(nil, track.name as NSString, nil)! as String)</string>
  """

    if let value = track.artist {
      output += "\n\t\t\t<key>Artist</key><string>\(CFXMLCreateStringByEscapingEntities(nil, value as NSString, nil)! as String)</string>"
    }
    if let value = track.composer {
      output += "\n\t\t\t<key>Artist</key><string>\(CFXMLCreateStringByEscapingEntities(nil, value as NSString, nil)! as String)</string>"
    }
    output += "\n\t\t\t<key>Kind</key><string>\(CFXMLCreateStringByEscapingEntities(nil, track.kind as NSString, nil)! as String)</string>"
    if let value = track.size {
      output += "\n\t\t\t<key>Size</key><integer>\(value)</integer>"
    }
    if let value = track.totalTime {
      output += "\n\t\t\t<key>Total Time</key><integer>\(value)</integer>"
    }
    if let value = track.discNumber {
      output += "\n\t\t\t<key>Disc Number</key><integer>\(value)</integer>"
    }
    if let value = track.trackNumber {
      output += "\n\t\t\t<key>Track Number</key><integer>\(value)</integer>"
    }
    if let value = track.year {
      output += "\n\t\t\t<key>Year</key><integer>\(value)</integer>"
    }
    if let value = track.bpm, value > 0 {
      output += "\n\t\t\t<key>BPM</key><integer>\(value)</integer>"
    }
    if let value = track.dateModified {
      output += "\n\t\t\t<key>Date Modified</key><date>\(dateFormatter.string(from: value))</date>"
    }
    output += "\n\t\t\t<key>Date Added</key><date>\(dateFormatter.string(from: track.dateAdded))</date>"
    if let value = track.bitRate {
      output += "\n\t\t\t<key>Bit Rate</key><integer>\(value)</integer>"
    }
    if let value = track.sampleRate {
      output += "\n\t\t\t<key>Sample Rate</key><integer>\(value)</integer>"
    }
    if let value = track.comments {
      output += "\n\t\t\t<key>Comments</key><string>\(CFXMLCreateStringByEscapingEntities(nil, value as NSString, nil)! as String)</string>"
    }
    if track.rating > 0 {
      output += "\n\t\t\t<key>Rating</key><integer>\(track.rating)</integer>"
    }
    if track.ratingComputed {
      output += "\n\t\t\t<key>Rating Computed</key><integer>\(track.ratingComputed)</integer>"
    }
    if let value = track.albumRating {
      output += "\n\t\t\t<key>Album Rating</key><integer>\(value)</integer>"
    }
    if let value = track.albumRatingComputed {
      output += "\n\t\t\t<key>Album Rating Computed</key><\(value)/>"
    }
    if let value = track.normalization {
      output += "\n\t\t\t<key>Normalization</key><integer>\(value)</integer>"
    }
    output += "\n\t\t\t<key>Persistent ID</key><string>\(track.persistentID)</string>"
    output += "\n\t\t\t<key>Track Type</key><string>\(CFXMLCreateStringByEscapingEntities(nil, track.trackType as NSString, nil)! as String)</string>"
    output += "\n\t\t\t<key>Location</key><string>\(CFXMLCreateStringByEscapingEntities(nil, track.location as NSString, nil)! as String)</string>"
    output += "\n\t\t\t<key>File Folder Count</key><integer>-1</integer>"
    output += "\n\t\t\t<key>Library Folder Count</key><integer>-1</integer>"
    output += "\n\t\t</dict>"
  }

  output += """

  \t</dict>
  \t<key>Playlists</key>
  \t<array>
  """

  print("Writing playlists...")
  // Build a tree of all playlists so that we can sort them in breadth-first order
  // First, build a lookup table so that we can determine the depth of each playlist
  var playlistIdToPlaylist: [String: ITunesPlaylist] = [:]
  for playlist in library.playlists {
    playlistIdToPlaylist[playlist.playlistPersistentID] = playlist
  }

  // Then calculate the depth of each playlist
  var playlistIdToDepth: [String: Int] = [:]
  for playlist in library.playlists {
    var depth = 0
    var iterator = playlist
    while let parentPersistentID = iterator.parentPersistentID {
      iterator = playlistIdToPlaylist[parentPersistentID]!
      depth += 1
    }
    playlistIdToDepth[playlist.playlistPersistentID] = depth
  }

  for playlist in library.playlists.sorted(by: { playlist1, playlist2 in
    if playlistIdToDepth[playlist1.playlistPersistentID]! == playlistIdToDepth[playlist2.playlistPersistentID]! {
      if playlistPersistentIdsWithChildren.contains(playlist1.playlistPersistentID) == playlistPersistentIdsWithChildren.contains(playlist2.playlistPersistentID) {
        return playlist1.name < playlist2.name
      }
      // Prioritize folders.
      return playlistPersistentIdsWithChildren.contains(playlist1.playlistPersistentID)
    }
    return playlistIdToDepth[playlist1.playlistPersistentID]! < playlistIdToDepth[playlist2.playlistPersistentID]!
  }) {
    //  guard let items = playlist.playlistItems, items.contains(where: { trackIdFilter.contains($0.trackID) }) else {
    //    continue
    //  }
    output += "\n\t\t<dict>"

    output += "\n\t\t\t<key>Name</key><string>\(CFXMLCreateStringByEscapingEntities(nil, playlist.name as NSString, nil)! as String)</string>"
    output += "\n\t\t\t<key>Description</key><string>\(CFXMLCreateStringByEscapingEntities(nil, playlist.description as NSString, nil)! as String)</string>"
    if let value = playlist.master, value {
      output += "\n\t\t\t<key>Master</key><\(value)/>"
    }
    output += "\n\t\t\t<key>Playlist ID</key><integer>\(playlist.playlistID)</integer>"
    output += "\n\t\t\t<key>Playlist Persistent ID</key><string>\(playlist.playlistPersistentID)</string>"
    if let value = playlist.parentPersistentID {
      output += "\n\t\t\t<key>Parent Persistent ID</key><string>\(value)</string>"
    }
    if let value = playlist.visible, !value {
      output += "\n\t\t\t<key>Visible</key><\(value)/>"
    }
    if playlist.name == "Music" {
      output += "\n\t\t\t<key>Distinguished Kind</key><integer>4</integer>"
      output += "\n\t\t\t<key>Music</key><true/>"
    }
    output += "\n\t\t\t<key>All Items</key><\(playlist.allItems)/>"
    if playlistPersistentIdsWithChildren.contains(playlist.playlistPersistentID) {
      output += "\n\t\t\t<key>Folder</key><true/>"
    }

    if let items = playlist.playlistItems {
      output += "\n\t\t\t<key>Playlist Items</key>"
      output += "\n\t\t\t<array>"
      for item in items {
        guard trackFilter(library.tracks[item.trackID]!) else {
          continue
        }
        //      guard trackIdFilter.contains(item.trackID) else {
        //        continue
        //      }
        output += "\n\t\t\t\t<dict>"
        output += "\n\t\t\t\t\t<key>Track ID</key><integer>\(item.trackID)</integer>"
        output += "\n\t\t\t\t</dict>"
      }
      output += "\n\t\t\t</array>"
    }
    output += "\n\t\t</dict>"
  }

  output += """

  \t</array>
  </dict>
  </plist>

  """


  try output.write(toFile: path, atomically: true, encoding: .utf8)
}
