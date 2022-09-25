import Foundation
import SQLite

public final class MediaItemTagsTable {
  public static let table = Table("mediaitem-tags")

  public static let mediaItemId = Expression<Int64>("mediaid")
  public static let tagId = Expression<Int64>("tagid")

  public static func createTable(db: Connection) throws {
    try db.run(table.create { t in
      t.column(mediaItemId, references: MediaItemTable.table, MediaItemTable.id)
      t.column(tagId, references: TagsTable.table, TagsTable.id)
    })
  }

  public static func connect(db: Connection, mediaItemId: Int64, tagId: Int64) throws {
    try db.run(table.insert(
      self.mediaItemId <- mediaItemId,
      self.tagId <- tagId
    ))
  }
}
