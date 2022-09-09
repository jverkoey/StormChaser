import Foundation

public struct ITunesPlaylistItem: Codable {
  public init(trackID: Int) {
    self.trackID = trackID
  }

  public let trackID: Int

  enum CodingKeys: String, CodingKey {
    case trackID = "Track ID"
  }
}
