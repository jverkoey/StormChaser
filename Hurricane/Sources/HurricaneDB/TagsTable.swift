import Foundation
import SQLite

public final class TagsTable {
  public static let table = Table("tags")

  public static let id = Expression<Int64>("id")
  public static let name = Expression<String>("name")

  public static func createTable(db: Connection) throws {
    try db.run(table.create { t in
      t.column(id, primaryKey: true)
      t.column(name, unique: true)
    })
  }

  public static func get(db: Connection, name: String) throws -> Int64? {
    let row = try db.pluck(table.select(id).filter(self.name == name))
    return row?[id]
  }

  public static func upsert(db: Connection, name: String) throws {
    try db.run(table.insert(
      self.name <- name
    ))
  }
}
