import Foundation

public struct ITunesLibrary: Codable {
  public init(majorVersion: Int, minorVersion: Int, date: Date, applicationVersion: String, features: Int, showContentRatings: Bool, musicFolder: String, libraryPersistentID: String, tracks: [Int : ITunesTrack], playlists: [ITunesPlaylist]) {
    self.majorVersion = majorVersion
    self.minorVersion = minorVersion
    self.date = date
    self.applicationVersion = applicationVersion
    self.features = features
    self.showContentRatings = showContentRatings
    self.musicFolder = musicFolder
    self.libraryPersistentID = libraryPersistentID
    self.tracks = tracks
    self.playlists = playlists
  }

  public let majorVersion: Int
  public let minorVersion: Int
  public let date: Date
  public let applicationVersion: String
  public let features: Int
  public let showContentRatings: Bool
  public let musicFolder: String
  public let libraryPersistentID: String

  public let tracks: [Int: ITunesTrack]
  public let playlists: [ITunesPlaylist]

  enum CodingKeys: String, CodingKey {
    case majorVersion = "Major Version"
    case minorVersion = "Minor Version"
    case date = "Date"
    case applicationVersion = "Application Version"
    case features = "Features"
    case showContentRatings = "Show Content Ratings"
    case musicFolder = "Music Folder"
    case libraryPersistentID = "Library Persistent ID"
    case tracks = "Tracks"
    case playlists = "Playlists"
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(self.majorVersion, forKey: .majorVersion)
    try container.encode(self.minorVersion, forKey: .minorVersion)
    try container.encode(self.date, forKey: .date)
    try container.encode(self.applicationVersion, forKey: .applicationVersion)
    try container.encode(self.features, forKey: .features)
    try container.encode(self.showContentRatings, forKey: .showContentRatings)
    try container.encode(self.musicFolder, forKey: .musicFolder)
    try container.encode(self.libraryPersistentID, forKey: .libraryPersistentID)
    try container.encode(self.tracks, forKey: .tracks)
    try container.encode(self.playlists, forKey: .playlists)
  }
}
