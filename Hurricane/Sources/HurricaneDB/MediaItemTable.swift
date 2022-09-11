import Foundation
#if canImport(iTunesLibrary)
import iTunesLibrary
#endif
import SQLite

#if canImport(iTunesLibrary) && !targetEnvironment(macCatalyst)
public func migrateItunesToDatabase(db: Connection) throws {
  let itunes = try ITLibrary(apiVersion: "1.0")

  try PlaylistsTable.createTable(db: db)
  try PlaylistsTable.populateAll(db: db, itunes: itunes)

  try ArtistTable.createTable(db: db)
  try AlbumTable.createTable(db: db)
  try MediaItemTable.createTable(db: db)
  try MediaItemTable.populateAll(db: db, itunes: itunes)
}
#endif

public final class MediaItemTable {
  public static let table = Table("mediaitems")

  public static let id = Expression<Int64>("id")
  public static let artistId = Expression<Int64?>("artistId")
  public static let albumId = Expression<Int64>("albumId")
  public static let title = Expression<String>("title")
  public static let sortTitle = Expression<String?>("sortTitle")
  public static let composer = Expression<String>("composer")
  public static let sortComposer = Expression<String?>("sortComposer")
  public static let rating = Expression<Int64>("rating")
  public static let ratingComputed = Expression<Bool>("ratingComputed")
  public static let albumRating = Expression<Int64?>("albumRating")
  public static let albumRatingComputed = Expression<Bool?>("albumRatingComputed")
  public static let genre = Expression<String>("genre")
  public static let kind = Expression<String?>("kind")
  public static let fileSize = Expression<Int64>("fileSize")
  public static let totalTime = Expression<Int64>("totalTime")
  public static let trackNumber = Expression<Int64>("trackNumber")
  public static let category = Expression<String?>("category")
  public static let description = Expression<String?>("description")
  public static let contentRating = Expression<String?>("contentRating")
  public static let modifiedDate = Expression<Date?>("modifiedDate")
  public static let addedDate = Expression<Date?>("addedDate")
  public static let bitrate = Expression<Int64>("bitrate")
  public static let sampleRate = Expression<Int64>("sampleRate")
  public static let beatsPerMinute = Expression<Int64>("beatsPerMinute")
  public static let playCount = Expression<Int64>("playCount")
  public static let location = Expression<String?>("location")
  public static let comments = Expression<String?>("comments")
  public static let grouping = Expression<String?>("grouping")
  public static let purchased = Expression<Bool>("purchased")
  public static let cloud = Expression<Bool>("cloud")
  public static let drmProtected = Expression<Bool>("drmProtected")
  public static let artworkAvailable = Expression<Bool>("artworkAvailable")
  public static let video = Expression<Bool>("video")
  public static let releaseDate = Expression<Date?>("releaseDate")
  public static let year = Expression<Int64>("year")
  public static let skipCount = Expression<Int64>("skipCount")
  public static let skipDate = Expression<Date?>("skipDate")
  public static let volumeAdjustment = Expression<Int64>("volumeAdjustment")
  public static let volumeNormalizationEnergy = Expression<Int64>("volumeNormalizationEnergy")
  public static let userDisabled = Expression<Bool>("userDisabled")
  public static let lastPlayedDate = Expression<Date?>("lastPlayedDate")
  public static let locationType = Expression<Int64>("locationType")
  public static let mediaKind = Expression<Int64>("mediaKind")
  public static let lyricsContentRating = Expression<Int64>("lyricsContentRating")
  public static let artworkFormat = Expression<Int64?>("artworkFormat")

  enum LocationType: Int64 {
    case unknown = 0
    case file = 1
    case url = 2
    case remote = 3
  }

  enum MediaKind: Int64 {
    case unknown = 1
    case song = 2
    case movie = 3
    case podcast = 4
    case audiobook = 5
    case pdfBooklet = 6
    case musicVideo = 7
    case tvShow = 8
    case interactiveBooklet = 9
    case homeVideo = 12
    case ringtone = 14
    case digitalBooklet = 15
    case iOSApplication = 16
    case voiceMemo = 17
    case iTunesU = 18
    case book = 19
    case pdfBook = 20
    case alertTone = 21
  }

  enum LyricsContentRating: Int64 {
    case none = 0
    case explicit = 1
    case clean = 2
  }

  enum ArtworkFormat: Int64 {
    case none = 0
    case bitmap = 1
    case JPEG = 2
    case JPEG2000 = 3
    case GIF = 4
    case PNG = 5
    case BMP = 6
    case TIFF = 7
    case PICT = 8
  }

  static func createTable(db: Connection) throws {
    try db.run(table.create { t in
      t.column(id, primaryKey: true)
      t.column(mediaKind)
      t.column(artistId)
      t.column(albumId)
      t.column(location)
      t.column(locationType)
      t.column(title)
      t.column(sortTitle)
      t.column(composer)
      t.column(sortComposer)
      t.column(rating)
      t.column(ratingComputed)
      t.column(albumRating)
      t.column(albumRatingComputed)
      t.column(genre)
      t.column(kind)
      t.column(fileSize)
      t.column(totalTime)
      t.column(trackNumber)
      t.column(category)
      t.column(description)
      t.column(contentRating)
      t.column(modifiedDate)
      t.column(addedDate)
      t.column(bitrate)
      t.column(sampleRate)
      t.column(beatsPerMinute)
      t.column(playCount)
      t.column(comments)
      t.column(grouping)
      t.column(purchased)
      t.column(cloud)
      t.column(drmProtected)
      t.column(artworkAvailable)
      t.column(video)
      t.column(releaseDate)
      t.column(year)
      t.column(skipCount)
      t.column(skipDate)
      t.column(volumeAdjustment)
      t.column(volumeNormalizationEnergy)
      t.column(userDisabled)
      t.column(lastPlayedDate)
      t.column(lyricsContentRating)
      t.column(artworkFormat)
    })
  }

#if canImport(iTunesLibrary) && !targetEnvironment(macCatalyst)
  static func populateAll(db: Connection, itunes: ITLibrary) throws {
    let artistTable = ArtistTable.self
    let albumTable = AlbumTable.self

    for item in itunes.allMediaItems {
      print(item.location?.absoluteString ?? item.title)

      if let artist = item.artist {
        try artistTable.update(db: db, artist: artist)
      }
      try albumTable.update(db: db, album: item.album)

      let imageDataFormat: Int64?
      if let artwork = item.artwork {
        // TODO: Write the artwork out to the artwork database.
        imageDataFormat = Int64(artwork.imageDataFormat.rawValue)
      } else {
        imageDataFormat = nil
      }
      let insert = table.upsert(
        id <- item.persistentID.int64Value,
        mediaKind <- Int64(item.mediaKind.rawValue),
        artistId <- item.artist?.persistentID.int64Value,
        albumId <- item.album.persistentID.int64Value,
        location <- item.location?.absoluteString,
        locationType <- Int64(item.locationType.rawValue),
        title <- item.title,
        sortTitle <- item.sortTitle,
        composer <- item.composer,
        sortComposer <- item.sortComposer,
        rating <- Int64(item.rating),
        ratingComputed <- item.isRatingComputed,
        albumRating <- item.value(forProperty: ITLibMediaItemPropertyAlbumRating) as? Int64,
        albumRatingComputed <- item.value(forProperty: ITLibMediaItemPropertyAlbumRatingComputed) as? Bool,
        genre <- item.genre,
        kind <- item.kind,
        fileSize <- Int64(item.fileSize),
        totalTime <- Int64(item.totalTime),
        trackNumber <- Int64(item.trackNumber),
        category <- item.category,
        description <- item.description,
        contentRating <- item.contentRating,
        modifiedDate <- item.modifiedDate,
        addedDate <- item.addedDate,
        bitrate <- Int64(item.bitrate),
        sampleRate <- Int64(item.sampleRate),
        beatsPerMinute <- Int64(item.beatsPerMinute),
        playCount <- Int64(item.playCount),
        comments <- item.comments,
        grouping <- item.grouping,
        purchased <- item.isPurchased,
        cloud <- item.isCloud,
        drmProtected <- item.isDRMProtected,
        artworkAvailable <- item.hasArtworkAvailable,
        video <- item.isVideo,
        releaseDate <- item.releaseDate,
        year <- Int64(item.year),
        skipCount <- Int64(item.skipCount),
        skipDate <- item.skipDate,
        volumeAdjustment <- Int64(item.volumeAdjustment),
        volumeNormalizationEnergy <- Int64(item.volumeNormalizationEnergy),
        userDisabled <- item.isUserDisabled,
        lastPlayedDate <- item.lastPlayedDate,
        lyricsContentRating <- Int64(item.lyricsContentRating.rawValue),
        artworkFormat <- imageDataFormat,
        onConflictOf: id
      )
      try db.run(insert)
    }
  }
#endif
}

/*

 /*! @abstract The video information of this media item (implies this media item is a video media item). */
 @property (readonly, nonatomic, retain, nullable) ITLibMediaItemVideoInfo* videoInfo;

 */
