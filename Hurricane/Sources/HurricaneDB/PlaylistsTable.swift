import Foundation
#if canImport(iTunesLibrary)
import iTunesLibrary
#endif
import SQLite

public final class PlaylistsTable {
  public static let table = Table("playlists")
  
  public static let id = Expression<Int64>("id")
  public static let parentId = Expression<Int64?>("parentId")
  public static let name = Expression<String>("name")
  public static let master = Expression<Bool>("master")
  public static let kind = Expression<PlaylistKind.RawValue>("kind")
  public static let items = Expression<String>("items")

  // DB representation for ITLibPlaylistKind
  public enum PlaylistKind: Int64 {
    case regular
    case smart
    case genius
    case folder
    case geniusMix
  }

  static func createTable(db: Connection) throws {
    try db.run(table.create { t in
      t.column(id, primaryKey: true)
      t.column(name)
      t.column(master)
      t.column(parentId)
      t.column(kind)
      t.column(items)
    })
  }

#if canImport(iTunesLibrary)
  static func populateAll(db: Connection, itunes: ITLibrary) throws {
    for playlist in itunes.allPlaylists {
      let itemIds = playlist.items.map { "\(String($0.persistentID.uint64Value, radix: 16, uppercase: true))" }.joined(separator: ",")
      let insert = table.insert(
        name <- playlist.name,
        id <- playlist.persistentID.int64Value,
        master <- playlist.isMaster,
        parentId <- playlist.parentID?.int64Value,
        kind <- Int64(playlist.kind.rawValue),
        items <- itemIds
      )
      try db.run(insert)
    }
  }
#endif
}
