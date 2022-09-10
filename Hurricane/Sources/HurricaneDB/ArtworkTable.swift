import Foundation
#if canImport(iTunesLibrary)
import iTunesLibrary
#endif
import SQLite

public final class ArtworkTable {
  public static let table = Table("artwork")

  public static let id = Expression<Int64>("id")
  public static let artwork = Expression<Data?>("artwork")

  public static func createTable(db: Connection) throws {
    try db.run(table.create { t in
      t.column(id, primaryKey: true)
      t.column(artwork)
    })
  }

#if canImport(iTunesLibrary)
  public static func insert(db: Connection, id: Int64, artwork: Data) throws {
    let insert = table.upsert(
      self.id <- id,
      self.artwork <- artwork,
      onConflictOf: self.id
    )
    try db.run(insert)
  }
#endif
}
