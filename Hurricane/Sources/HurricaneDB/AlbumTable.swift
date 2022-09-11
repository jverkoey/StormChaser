import Foundation
#if canImport(iTunesLibrary)
import iTunesLibrary
#endif
import SQLite

// For ITLibAlbum
public final class AlbumTable {
  public static let table = Table("albums")

  public static let id = Expression<Int64>("id")
  public static let title = Expression<String?>("title")
  public static let sortTitle = Expression<String?>("sortTitle")
  public static let compilation = Expression<Bool>("compilation")
  public static let discCount = Expression<Int64>("discCount")
  public static let discNumber = Expression<Int64>("discNumber")
  public static let rating = Expression<Int64>("rating")
  public static let ratingComputed = Expression<Bool>("ratingComputed")
  public static let gapless = Expression<Bool>("gapless")
  public static let trackCount = Expression<Int64>("trackCount")
  public static let albumArtist = Expression<String?>("albumArtist")
  public static let sortAlbumArtist = Expression<String?>("sortAlbumArtist")

  static var seenIds = Set<Int64>()

  static func createTable(db: Connection) throws {
    try db.run(table.create { t in
      t.column(id, primaryKey: true)
      t.column(title)
      t.column(sortTitle)
      t.column(compilation)
      t.column(discCount)
      t.column(discNumber)
      t.column(rating)
      t.column(ratingComputed)
      t.column(gapless)
      t.column(trackCount)
      t.column(albumArtist)
      t.column(sortAlbumArtist)
    })
  }

#if canImport(iTunesLibrary) && !targetEnvironment(macCatalyst)
  static func update(db: Connection, album: ITLibAlbum) throws {
    if seenIds.contains(album.persistentID.int64Value) {
      return
    }
    let insert = table.upsert(
      id <- album.persistentID.int64Value,
      title <- album.title,
      sortTitle <- album.sortTitle,
      compilation <- album.isCompilation,
      discCount <- Int64(album.discCount),
      discNumber <- Int64(album.discNumber),
      rating <- Int64(album.rating),
      ratingComputed <- album.isRatingComputed,
      gapless <- album.isGapless,
      trackCount <- Int64(album.trackCount),
      albumArtist <- album.albumArtist,
      sortAlbumArtist <- album.sortAlbumArtist,
      onConflictOf: id
    )
    try db.run(insert)
  }
#endif
}
