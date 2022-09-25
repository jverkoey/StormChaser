import Foundation

public struct ITunesTrack {
  public init(trackID: Int, name: String, artist: String? = nil, composer: String? = nil, grouping: String? = nil, kind: String, size: Int? = nil, totalTime: Int? = nil, discNumber: Int? = nil, trackNumber: Int? = nil, year: Int? = nil, bpm: Int? = nil, dateModified: Date? = nil, dateAdded: Date, bitRate: Int? = nil, sampleRate: Int? = nil, comments: String? = nil, albumRating: Int? = nil, albumRatingComputed: Bool? = nil, normalization: Int? = nil, persistentID: String, trackType: String, location: String, fileFolderCount: Int? = nil, libraryFolderCount: Int? = nil, rating: Int, ratingComputed: Bool) {
    self.trackID = trackID
    self.name = name
    self.artist = artist
    self.composer = composer
    self.grouping = grouping
    self.kind = kind
    self.size = size
    self.totalTime = totalTime
    self.discNumber = discNumber
    self.trackNumber = trackNumber
    self.year = year
    self.bpm = bpm
    self.dateModified = dateModified
    self.dateAdded = dateAdded
    self.bitRate = bitRate
    self.sampleRate = sampleRate
    self.comments = comments
    self.albumRating = albumRating
    self.albumRatingComputed = albumRatingComputed
    self.normalization = normalization
    self.persistentID = persistentID
    self.trackType = trackType
    self.location = location
    self.fileFolderCount = fileFolderCount
    self.libraryFolderCount = libraryFolderCount
    self.rating = rating
    self.ratingComputed = ratingComputed
  }
  
  public let trackID: Int
  public let name: String
  public let artist: String?
  public let composer: String?
  public let grouping: String?
  public let kind: String
  public let size: Int?
  public let totalTime: Int?
  public let discNumber: Int?
  public let trackNumber: Int?
  public let year: Int?
  public let bpm: Int?
  public let dateModified: Date?
  public let dateAdded: Date
  public let bitRate: Int?
  public let sampleRate: Int?
  public let comments: String?
  public let albumRating: Int?
  public let albumRatingComputed: Bool?
  public let normalization: Int?
  public let persistentID: String
  public let trackType: String
  public let location: String
  public let fileFolderCount: Int?
  public let libraryFolderCount: Int?
  public let rating: Int
  public let ratingComputed: Bool
}
