import Foundation
#if canImport(ITunesLibrary)
import iTunesLibrary
#endif
import SQLite

public final class ArtistTable {
  public static let table = Table("artists")

  public static let id = Expression<Int64>("id")
  public static let name = Expression<String?>("name")
  public static let sortName = Expression<String?>("sortName")

  static var seenIds = Set<Int64>()

  static func createTable(db: Connection) throws {
    try db.run(table.create { t in
      t.column(id, primaryKey: true)
      t.column(name)
      t.column(sortName)
    })
  }

#if canImport(ITunesLibrary)
  static func update(db: Connection, artist: ITLibArtist) throws {
    if seenIds.contains(artist.persistentID.int64Value) {
      return
    }
    let insert = table.upsert(
      id <- artist.persistentID.int64Value,
      name <- artist.name,
      sortName <- artist.sortName,
      onConflictOf: id
    )
    try db.run(insert)
  }
#endif
}
