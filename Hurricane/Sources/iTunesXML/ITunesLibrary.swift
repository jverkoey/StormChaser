import Foundation

public struct ITunesLibrary {
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
}
